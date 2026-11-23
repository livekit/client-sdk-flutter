import 'dart:convert' show json;

import 'package:fixnum/fixnum.dart';

import '../exceptions.dart';
import '../logger.dart';
import '../options.dart';
import '../proto/livekit_rtc.pb.dart' as lk_models;
import 'http_client.dart';
import 'websocket.dart' show WebSocketException;

class RegionUrlProvider {
  Uri serverUrl;

  String token;

  final NetworkOptions networkOptions;

  lk_models.RegionSettings? regionSettings;

  List<lk_models.RegionInfo> attemptedRegions = [];

  int lastUpdateAt = 0;

  int settingsCacheTime = 5000; // 5 seconds

  RegionUrlProvider({
    required String url,
    required this.token,
    this.networkOptions = const NetworkOptions(),
  }) : serverUrl = Uri.parse(url);

  void updateToken(String token) {
    this.token = token;
  }

  bool isCloud() => isCloudUrl(serverUrl);

  Uri getServerUrl() {
    return serverUrl;
  }

  Future<String?> getNextBestRegionUrl() async {
    if (!isCloud()) {
      throw Exception('region availability is only supported for LiveKit Cloud domains');
    }
    if (regionSettings == null || DateTime.timestamp().millisecondsSinceEpoch - lastUpdateAt > settingsCacheTime) {
      regionSettings = await fetchRegionSettings();
    }
    final regionsLeft = regionSettings?.regions.where(
      (region) => !attemptedRegions.any((attempted) => attempted.region == region.region),
    );
    if (regionsLeft?.isNotEmpty ?? false) {
      final nextRegion = regionsLeft!.first;
      attemptedRegions.add(nextRegion);
      logger.fine('next region: ${nextRegion.region}');
      return nextRegion.url;
    } else {
      return null;
    }
  }

  void resetAttempts() {
    attemptedRegions = [];
  }

  /* @internal */
  Future<lk_models.RegionSettings> fetchRegionSettings() async {
    final url = '${getCloudConfigUrl(serverUrl)}/regions';
    final regionSettingsResponse = await sdkHttpGet(
      Uri.parse(url),
      headers: {
        'authorization': 'Bearer $token',
      },
      networkOptions: networkOptions,
    );
    if (regionSettingsResponse.statusCode == 200) {
      final mapData = json.decode(regionSettingsResponse.body);
      final regions = (mapData['regions'] as List<dynamic>)
          .map(
            (region) => lk_models.RegionInfo(
              distance: Int64(int.parse(region['distance'])),
              region: region['region'],
              url: region['url'],
            ),
          )
          .toList();
      lastUpdateAt = DateTime.timestamp().millisecondsSinceEpoch;
      return lk_models.RegionSettings(
        regions: _trustedRegions(regions),
      );
    } else {
      throw ConnectException(
        'Could not fetch region settings: ${regionSettingsResponse.body}, status: ${regionSettingsResponse.statusCode}',
        reason: regionSettingsResponse.statusCode == 401
            ? ConnectionErrorReason.NotAllowed
            : ConnectionErrorReason.InternalError,
        statusCode: regionSettingsResponse.statusCode,
      );
    }
  }

  void setServerReportedRegions(lk_models.RegionSettings regions) {
    regionSettings = lk_models.RegionSettings(
      regions: _trustedRegions(regions.regions),
    );
    lastUpdateAt = DateTime.timestamp().millisecondsSinceEpoch;
  }

  /// Keeps only the regions this SDK may fail over to, reporting what it dropped.
  ///
  /// Both sources of a region list are network input, and every URL kept here is later connected
  /// to with the participant token. See [isTrustedRegionUrl].
  List<lk_models.RegionInfo> _trustedRegions(List<lk_models.RegionInfo> regions) {
    final trusted = regions.where((region) => isTrustedRegionUrl(region.url)).toList();
    final rejected = regions.length - trusted.length;
    if (rejected > 0) {
      logger.warning('ignoring $rejected of ${regions.length} regions: not an encrypted LiveKit Cloud URL');
    }
    return trusted;
  }

  String getCloudConfigUrl(Uri serverUrl) {
    return '${serverUrl.scheme.replaceAll('ws', 'http')}://${serverUrl.host}/settings';
  }
}

extension RegionInfoExtension on lk_models.RegionInfo {
  lk_models.RegionInfo fromJson(Map<String, dynamic> json) => lk_models.RegionInfo(
    region: json['region'],
    url: json['url'],
    distance: json['distance'],
  );
}

extension RegionSettingsExtension on lk_models.RegionSettings {
  lk_models.RegionSettings fromJson(Map<String, dynamic> json) => lk_models.RegionSettings(
    regions: json['regions'].map((region) => lk_models.RegionInfo.fromJson(region)).toList(),
  );
}

/// Whether [uri] names a LiveKit Cloud project.
///
/// Matched on the suffix, not with `contains`: a host only belongs to LiveKit Cloud when it ends
/// in one of these domains. `project.livekit.cloud.example.com` contains `.livekit.cloud` but is
/// someone else's host, and treating it as Cloud would send it the region request — with the
/// participant token attached.
bool isCloudUrl(Uri uri) {
  final host = uri.host.toLowerCase();
  return host.endsWith('.livekit.cloud') || host.endsWith('.livekit.run');
}

/// Whether [url] is a region URL the SDK may fail over to.
///
/// A region list arrives over the network — from `/settings/regions` and from the regions the
/// server reports over signalling — and the SDK authenticates to whatever it names, sending the
/// participant token as a bearer header. Each entry is therefore checked on its own merits rather
/// than inheriting trust from the server URL the application supplied, and `ws`/`http` entries are
/// refused so a region list cannot move that exchange onto cleartext.
bool isTrustedRegionUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'wss' && scheme != 'https') return false;
  return isCloudUrl(uri);
}

/// Whether a failed connection attempt may be retried against a different LiveKit Cloud region.
///
/// LiveKit Cloud signals project-level region pinning by returning 403 on the RTC paths when the
/// project is not allowed in the region the client geo-routed to. `/settings/regions` is
/// deliberately left reachable so the client can discover its allowed regions and connect there,
/// so a 403 must not be treated as terminal.
///
/// A 401 stays terminal: no other region will accept a token this one rejected.
///
/// We key on the status rather than the server's error message because that message is an
/// unversioned human-readable string; matching it would let a copy edit break already-shipped
/// clients. If a 403 really was a permissions failure rather than region pinning, every region
/// attempt fails the same way and the original error still surfaces — at the cost of one extra
/// region lookup.
bool canFailOverToAnotherRegion(Object error) {
  if (error is WebSocketException) {
    return true;
  }
  if (error is ConnectException) {
    if (error.reason == ConnectionErrorReason.NotAllowed) {
      return error.statusCode == 403;
    }
    return true;
  }
  return false;
}

String toHttpUrl(String url) {
  if (url.startsWith('ws')) {
    return url.replaceFirst('ws', 'http');
  }
  return url;
}

String toWebsocketUrl(String url) {
  if (url.startsWith('http')) {
    return url.replaceFirst('http', 'ws');
  }
  return url;
}
