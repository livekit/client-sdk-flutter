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

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_client/src/proto/livekit_models.pb.dart' as lk_models;
import 'package:livekit_client/src/proto/livekit_rtc.pb.dart' as lk_rtc;
import 'package:livekit_client/src/utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<lk_rtc.JoinRequest> v1JoinRequest(ConnectOptions connectOptions) async {
    final uri = await Utils.buildV1Uri(
      'ws://localhost:7880',
      token: 'token',
      connectOptions: connectOptions,
      roomOptions: const RoomOptions(),
    );
    expect(uri.path, '/rtc/v1');
    final wrapped = lk_rtc.WrappedJoinRequest.fromBuffer(base64Decode(uri.queryParameters['join_request']!));
    return lk_rtc.JoinRequest.fromBuffer(wrapped.joinRequest);
  }

  test('v1 join request advertises the client protocol, as v0 does with client_protocol', () async {
    final v0 = await Utils.buildV0Uri(
      'ws://localhost:7880',
      token: 'token',
      connectOptions: const ConnectOptions(),
      roomOptions: const RoomOptions(),
    );
    final join = await v1JoinRequest(const ConnectOptions());

    expect(join.clientInfo.sdk, lk_models.ClientInfo_SDK.FLUTTER);
    expect(join.clientInfo.version, LiveKitClient.version);
    expect(join.clientInfo.hasClientProtocol(), isTrue);
    expect(join.clientInfo.clientProtocol.toString(), v0.queryParameters['client_protocol']);
    expect(join.clientInfo.clientProtocol, ClientProtocolVersion.current.wireValue);
  });

  test('v1 join request carries a configured client protocol', () async {
    final join = await v1JoinRequest(const ConnectOptions(clientProtocolVersion: ClientProtocolVersion.v0));
    expect(join.clientInfo.clientProtocol, ClientProtocolVersion.v0.wireValue);
  });

  test('ConnectOptions.copyWith keeps every field it is not asked to change', () {
    const options = ConnectOptions(
      autoSubscribe: false,
      protocolVersion: ProtocolVersion.v12,
      clientProtocolVersion: ClientProtocolVersion.v0,
      singlePeerConnection: true,
    );
    // Engine.connect falls back to dual peer connection this way.
    final fallback = options.copyWith(singlePeerConnection: false);
    expect(fallback.singlePeerConnection, isFalse);
    expect(fallback.autoSubscribe, isFalse);
    expect(fallback.protocolVersion, ProtocolVersion.v12);
    expect(fallback.clientProtocolVersion, ClientProtocolVersion.v0);
    expect(fallback.timeouts, options.timeouts);
    expect(fallback.rtcConfiguration, options.rtcConfiguration);
  });

  test('v1 validate URL keeps the join request of the signal URL', () async {
    final rtc = await Utils.buildV1Uri(
      'wss://example.livekit.cloud',
      token: 'token',
      connectOptions: const ConnectOptions(),
      roomOptions: const RoomOptions(),
    );
    final validate = Utils.buildV1ValidateUri(rtc);

    expect(validate.scheme, 'https');
    expect(validate.path, '/rtc/v1/validate');
    expect(validate.queryParameters['join_request'], rtc.queryParameters['join_request']);
    // native clients send the token in the Authorization header only
    expect(rtc.queryParameters.containsKey('access_token'), isFalse);
    expect(validate.queryParameters.containsKey('access_token'), isFalse);
    expect(Utils.buildV1ValidateUri(Uri.parse('ws://h/rtc/v1?a=1'), forceSecure: true).scheme, 'https');
    expect(Utils.buildV1ValidateUri(Uri.parse('ws://h/rtc/v1?a=1')).toString(), 'http://h/rtc/v1/validate?a=1');
  });
}
