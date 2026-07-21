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

import '../../options.dart';
import '../../support/region_url_provider.dart';
import '../../types/other.dart';
import 'checker.dart';

/// Verifies that a connection via a TURN relay can be established.
class TURNCheck extends Checker {
  TURNCheck(super.url, super.token, {super.options, super.room});

  @override
  String get description => 'Can connect via TURN';

  @override
  Future<void> perform() async {
    if (isCloudUrl(Uri.parse(url))) {
      appendMessage('Using region specific url');
      url = await RegionUrlProvider(
            url: url,
            token: token,
            networkOptions: networkOptions,
          ).getNextBestRegionUrl() ??
          url;
    }
    final joinRes = await signalJoin(url);

    var hasTLS = false;
    var hasTURN = false;
    var hasSTUN = false;

    for (final iceServer in joinRes.iceServers) {
      for (final serverUrl in iceServer.urls) {
        if (serverUrl.startsWith('turn:')) {
          hasTURN = true;
          hasSTUN = true;
        } else if (serverUrl.startsWith('turns:')) {
          hasTURN = true;
          hasSTUN = true;
          hasTLS = true;
        }
        if (serverUrl.startsWith('stun:')) {
          hasSTUN = true;
        }
      }
    }
    if (!hasSTUN) {
      appendWarning('No STUN servers configured on server side.');
    } else if (hasTURN && !hasTLS) {
      appendWarning('TURN is configured server side, but TURN/TLS is unavailable.');
    }
    if (connectOptions?.rtcConfiguration.iceServers != null || hasTURN) {
      final baseOptions = connectOptions ?? const ConnectOptions();
      await room.connect(
        url,
        token,
        connectOptions: ConnectOptions(
          autoSubscribe: baseOptions.autoSubscribe,
          rtcConfiguration: baseOptions.rtcConfiguration.copyWith(
            iceTransportPolicy: RTCIceTransportPolicy.relay,
          ),
          protocolVersion: baseOptions.protocolVersion,
          clientProtocolVersion: baseOptions.clientProtocolVersion,
          timeouts: baseOptions.timeouts,
        ),
      );
    } else {
      appendWarning('No TURN servers configured.');
      skip();
    }
  }
}
