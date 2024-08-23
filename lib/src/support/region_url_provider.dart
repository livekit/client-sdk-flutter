import 'dart:convert' show json;

import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart' as http;

import '../exceptions.dart';
import '../logger.dart';
import '../proto/livekit_rtc.pb.dart' as lk_models;

class RegionUrlProvider {
  Uri serverUrl;

  String token;

  lk_models.RegionSettings? regionSettings;

  List<lk_models.RegionInfo> attemptedRegions = [];

  int lastUpdateAt = 0;

  int settingsCacheTime = 3000;

  RegionUrlProvider({required String url, required this.token})
      : serverUrl = Uri.parse(url);

  updateToken(String token) {
    this.token = token;
  }

  bool isCloud() => isCloudUrl(serverUrl);

  Uri getServerUrl() {
    return serverUrl;
  }

  Future<String?> getNextBestRegionUrl() async {
    if (!isCloud()) {
      throw Exception(
          'region availability is only supported for LiveKit Cloud domains');
    }
    if (regionSettings == null ||
        DateTime.now().microsecondsSinceEpoch - lastUpdateAt >
            settingsCacheTime) {
      regionSettings = await fetchRegionSettings();
    }
    final regionsLeft = regionSettings?.regions.where(
      (region) => !attemptedRegions
          .any((attempted) => attempted.region == region.region),
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

  resetAttempts() {
    attemptedRegions = [];
  }

  /* @internal */
  Future<lk_models.RegionSettings> fetchRegionSettings() async {
    var url = '${getCloudConfigUrl(serverUrl)}/regions';
    http.Response regionSettingsResponse =
        await http.get(Uri.parse(url), headers: {
      'authorization': 'Bearer $token',
    });
    if (regionSettingsResponse.statusCode == 200) {
      var mapData = json.decode(regionSettingsResponse.body);
      var regions = (mapData['regions'] as List<dynamic>)
          .map((region) => lk_models.RegionInfo(
              distance: Int64(int.parse(region['distance'])),
              region: region['region'],
              url: region['url']))
          .toList();
      var regionSettings = lk_models.RegionSettings(
        regions: regions,
      );
      lastUpdateAt = DateTime.now().microsecondsSinceEpoch;
      return regionSettings;
    } else {
      throw ConnectException(
          'Could not fetch region settings: ${regionSettingsResponse.body}, status: ${regionSettingsResponse.statusCode}',
          reason: regionSettingsResponse.statusCode == 401
              ? ConnectionErrorReason.NotAllowed
              : ConnectionErrorReason.InternalError,
          statusCode: regionSettingsResponse.statusCode);
    }
  }

  setServerReportedRegions(lk_models.RegionSettings regions) {
    regionSettings = regions;
    lastUpdateAt = DateTime.now().millisecondsSinceEpoch;
  }

  String getCloudConfigUrl(Uri serverUrl) {
    return '${serverUrl.scheme.replaceAll('ws', 'http')}://${serverUrl.host}/settings';
  }
}

extension RegionInfoExtension on lk_models.RegionInfo {
  lk_models.RegionInfo fromJson(Map<String, dynamic> json) =>
      lk_models.RegionInfo(
        region: json['region'],
        url: json['url'],
        distance: json['distance'],
      );
}

extension RegionSettingsExtension on lk_models.RegionSettings {
  lk_models.RegionSettings fromJson(Map<String, dynamic> json) =>
      lk_models.RegionSettings(
        regions: json['regions']
            .map((region) => lk_models.RegionInfo.fromJson(region))
            .toList(),
      );
}

bool isCloudUrl(Uri uri) {
  return uri.host.contains('.livekit.cloud') ||
      uri.host.contains('.livekit.run');
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
