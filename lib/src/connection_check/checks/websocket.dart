// Copyright 2026 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import '../../proto/livekit_models.pb.dart' as lk_models;
import '../../proto/livekit_rtc.pb.dart' as lk_rtc;
import '../../support/region_url_provider.dart';
import 'checker.dart';

/// Verifies that a WebSocket connection to the LiveKit server can be
/// established (signal connection).
class WebSocketCheck extends Checker {
  WebSocketCheck(super.url, super.token, {super.options, super.room});

  @override
  String get description => 'Connecting to signal connection via WebSocket';

  @override
  Future<void> perform() async {
    if (url.startsWith('ws:') || url.startsWith('http:')) {
      appendWarning('Server is insecure, clients may block connections to it');
    }

    lk_rtc.JoinResponse? joinRes;
    Object? lastError;
    try {
      joinRes = await signalJoin(url);
    } catch (err) {
      lastError = err;
      if (isCloudUrl(Uri.parse(url))) {
        appendMessage('Initial connection failed with error ${messageFor(err)}. Retrying with region fallback');
        final regionProvider = RegionUrlProvider(
          url: url,
          token: token,
          networkOptions: networkOptions,
        );
        final regionUrl = await regionProvider.getNextBestRegionUrl();
        if (regionUrl != null) {
          joinRes = await signalJoin(regionUrl);
          appendMessage('Fallback to region worked. To avoid initial connections failing, '
              'ensure you\'re calling room.prepareConnection() ahead of time');
        }
      }
    }
    if (joinRes != null) {
      appendMessage('Connected to server, version ${joinRes.serverVersion}.');
      if (joinRes.hasServerInfo() &&
          joinRes.serverInfo.edition == lk_models.ServerInfo_Edition.Cloud &&
          joinRes.serverInfo.region.isNotEmpty) {
        appendMessage('LiveKit Cloud: ${joinRes.serverInfo.region}');
      }
    } else {
      appendError('Websocket connection could not be established'
          '${lastError != null ? ': ${messageFor(lastError)}' : ''}');
    }
  }
}
