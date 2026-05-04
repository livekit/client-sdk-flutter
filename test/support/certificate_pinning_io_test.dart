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

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';

import 'package:livekit_client/src/exceptions.dart';
import 'package:livekit_client/src/options.dart';
import 'package:livekit_client/src/support/certificate_pinning.dart';
import 'package:livekit_client/src/support/http_client.dart';
import 'package:livekit_client/src/support/websocket.dart';

void main() {
  test('allows certificate-byte trust without SPKI pins', () async {
    final server = await _TlsTestServer.start();
    addTearDown(server.close);

    final response = await sdkHttpGet(
      Uri.parse('https://localhost:${server.port}/settings'),
      networkOptions: NetworkOptions(
        certificatePinning: CertificatePinningOptions(
          rules: [
            CertificatePinningRule(
              hosts: const ['localhost'],
              trustedCertificateBytes: [_pemBytes(_localhostCertificatePem)],
            ),
          ],
        ),
      ),
    );

    expect(response.statusCode, 200);
    expect(response.body, 'OK');
    expect(server.receivedText, contains('GET /settings HTTP/1.1'));
  });

  test('validates SPKI pins before sending HTTP request bytes', () async {
    final server = await _TlsTestServer.start();
    addTearDown(server.close);

    await expectLater(
      sdkHttpGet(
        Uri.parse('https://localhost:${server.port}/rtc'),
        headers: const {'Authorization': 'Bearer token'},
        networkOptions: NetworkOptions(
          certificatePinning: CertificatePinningOptions(
            rules: [
              CertificatePinningRule(
                hosts: const ['localhost'],
                primaryPins: const ['sha256/not-the-presented-pin'],
                trustedCertificateBytes: [_pemBytes(_localhostCertificatePem)],
              ),
            ],
          ),
        ),
      ),
      throwsA(isA<CertificatePinningException>()),
    );

    await server.waitForConnection();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(server.receivedBytes, isEmpty);
  });

  test('validates SPKI pins before sending WSS request bytes', () async {
    final server = await _TlsTestServer.start();
    addTearDown(server.close);

    await expectLater(
      LiveKitWebSocket.connect(
        Uri.parse('wss://localhost:${server.port}/rtc'),
        headers: const {'Authorization': 'Bearer token'},
        networkOptions: NetworkOptions(
          certificatePinning: CertificatePinningOptions(
            rules: [
              CertificatePinningRule(
                hosts: const ['localhost'],
                primaryPins: const ['sha256/not-the-presented-pin'],
                trustedCertificateBytes: [_pemBytes(_localhostCertificatePem)],
              ),
            ],
          ),
        ),
      ),
      throwsA(isA<CertificatePinningException>()),
    );

    await server.waitForConnection();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(server.receivedBytes, isEmpty);
  });

  test('allows matching certificate-byte trust and SPKI pins together', () async {
    final server = await _TlsTestServer.start();
    addTearDown(server.close);

    final response = await sdkHttpGet(
      Uri.parse('https://localhost:${server.port}/rtc'),
      headers: const {'Authorization': 'Bearer token'},
      networkOptions: NetworkOptions(
        certificatePinning: CertificatePinningOptions(
          rules: [
            CertificatePinningRule(
              hosts: const ['localhost'],
              primaryPins: [certificateSpkiSha256Pin(_certificateDerFromPem(_localhostCertificatePem))],
              trustedCertificateBytes: [_pemBytes(_localhostCertificatePem)],
            ),
          ],
        ),
      ),
    );

    expect(response.statusCode, 200);
    expect(server.receivedText, contains('authorization: Bearer token'));
  });
}

class _TlsTestServer {
  final io.SecureServerSocket _server;
  final _connected = Completer<void>();
  final _receivedBytes = <int>[];
  final _sockets = <io.SecureSocket>[];
  late final StreamSubscription<io.SecureSocket> _subscription;

  _TlsTestServer._(this._server) {
    _subscription = _server.listen(_handleSocket);
  }

  int get port => _server.port;

  List<int> get receivedBytes => List.unmodifiable(_receivedBytes);

  String get receivedText => ascii.decode(_receivedBytes, allowInvalid: true);

  static Future<_TlsTestServer> start() async {
    final context = io.SecurityContext()
      ..useCertificateChainBytes(_pemBytes(_localhostCertificatePem))
      ..usePrivateKeyBytes(_pemBytes(_localhostPrivateKeyPem));
    final server = await io.SecureServerSocket.bind(
      io.InternetAddress.loopbackIPv4,
      0,
      context,
    );
    return _TlsTestServer._(server);
  }

  Future<void> waitForConnection() async {
    if (_connected.isCompleted) {
      return;
    }
    await _connected.future.timeout(const Duration(seconds: 1), onTimeout: () {});
  }

  Future<void> close() async {
    await _subscription.cancel();
    for (final socket in _sockets) {
      socket.destroy();
    }
    await _server.close();
  }

  void _handleSocket(io.SecureSocket socket) {
    _sockets.add(socket);
    if (!_connected.isCompleted) {
      _connected.complete();
    }

    socket.listen((data) {
      _receivedBytes.addAll(data);
      if (receivedText.contains('\r\n\r\n')) {
        socket.add(ascii.encode('HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK'));
        unawaited(socket.flush().then((_) => socket.close()));
      }
    });
  }
}

List<int> _pemBytes(String pem) => ascii.encode(pem);

List<int> _certificateDerFromPem(String pem) {
  final base64Body = pem.split('\n').where((line) => line.isNotEmpty && !line.startsWith('-----')).join();
  return base64Decode(base64Body);
}

const _localhostCertificatePem = '''
-----BEGIN CERTIFICATE-----
MIIDPTCCAiWgAwIBAgIUAsxf3tE9w4P9nBBZp+I4U7mFWhowDQYJKoZIhvcNAQEL
BQAwGjEYMBYGA1UEAwwPTGl2ZUtpdCBUZXN0IENBMB4XDTI2MDUwNTAwNDA1MloX
DTM2MDUwMjAwNDA1MlowFDESMBAGA1UEAwwJbG9jYWxob3N0MIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoLdtYxvAcqnaFXMYu/g57Zn2LhTBJBYjJ5UB
aVKcbtk5z0IjC+OJe75x6DcQS+HbH4cHF7FY52CLC2oxUsAIdHmXtN1UHrjIDFBC
nSTwAIpsO9NKdwmRB1cGC8vfwA2gWKaedHDwO9fLk7RC5kxVw23OuOPbdn6cKnkv
U4NZkUULyYk/bk5AFscLFeQkDf/0rAbibG+EKeoJ4VAQB8CYs3OeQm2Sxig7Oy09
n5KA5+UjxjeVTJzAC0JqqeBs9ISNJ7+vlsfLng/S/xpnnzRkMYuG8sFFseN3pA9Y
Ur/WlgD7fSWKbEOxCsWiFKP0yUq8VpEeBRA48ERp1AHv/Q99pQIDAQABo4GAMH4w
GgYDVR0RBBMwEYIJbG9jYWxob3N0hwR/AAABMBMGA1UdJQQMMAoGCCsGAQUFBwMB
MAsGA1UdDwQEAwIFoDAdBgNVHQ4EFgQULlshilL3OsKKeYGZiv0knrBXr1YwHwYD
VR0jBBgwFoAU+YOp4KUxVvCyeDTLAq2oMvOAdQowDQYJKoZIhvcNAQELBQADggEB
AA06Tu7DQrhoMlpH1GEqnHbaxZXjlp7D6SnJxZ7Sg1iNtolRRKZ0AAhVJ5LaRhiN
M7lmbOpxbI87GxIzI4DkerU4i23tqtrI3/xx2l08FIyl46pFWtHKb8zwAgtigVwO
rIhDsCFSwDP8srWTaVwcazlMDzr8KKB2uHV09aDL+ZI1czSTboPcdsJtQPbElGqe
hEIgiyr6t/CGVUjpERKJCv9CpJ+gjEZMYztseyWbhMLaooURFBhDTyNRCRq85pJ2
xytNnc8A/nSkIDn2lYHFmeGlhwYrGDcT7itYaVQkgBrSFfmPHH4+/SGduS92qIxg
8lE1W7hFxs9bHcK7ys+1Ggc=
-----END CERTIFICATE-----
''';

const _localhostPrivateKeyPem = '''
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCgt21jG8ByqdoV
cxi7+DntmfYuFMEkFiMnlQFpUpxu2TnPQiML44l7vnHoNxBL4dsfhwcXsVjnYIsL
ajFSwAh0eZe03VQeuMgMUEKdJPAAimw700p3CZEHVwYLy9/ADaBYpp50cPA718uT
tELmTFXDbc6449t2fpwqeS9Tg1mRRQvJiT9uTkAWxwsV5CQN//SsBuJsb4Qp6gnh
UBAHwJizc55CbZLGKDs7LT2fkoDn5SPGN5VMnMALQmqp4Gz0hI0nv6+Wx8ueD9L/
GmefNGQxi4bywUWx43ekD1hSv9aWAPt9JYpsQ7EKxaIUo/TJSrxWkR4FEDjwRGnU
Ae/9D32lAgMBAAECggEAJjQD/hOaNwd2DjQ6VHBIgNjgwopvcN8MQzvxxnH7OoRL
cB92CjzvsOkP1ZXFO2x4NHHZ90FSc0mpM7DuAZAhUmKW88jK1rSw5PBtLUKbBF3j
JYNvx4UQIvEGQGaZjOMQUxJkRySTjn4Y58bpQioyFs7y3VNYlz24bIY7ADyQXW3t
2WDtKEe4+2FwRciuTSNe7EVtCL+0jsADOTpEwc1SPK5z8wpkCPUUB6LYIiCO480x
3qqY7b9RHRrZveblAP+v/S8KMP37ZMMvvgjC7FsH8MTbtfkxrr4R/fXnPI7sinOT
REZ/+01wPUwxFzde61vMfUKEHA2zd+sILX6RVJNkjwKBgQDgLdnSa6ajJuCLmvvI
NCRuS3fJz9pqomlMsBIadKFJsR13LUgdX/PAgCpruXfQyKbIa251NqDvxBEwmjI8
ITTOI+BCqUyo9ekXsA842mJ9kBr3QjJmq4jGJPidOqZxw+VEoJ880mZJiiMMJ9Jh
vLtfGUYUZfOth/GySQX3vZ0kJwKBgQC3h34vHMj3r6YnBKQLuiW8IpWyeFXxatWj
22nA0uv4umX7zoD/MQ8ixzCbFELZhuz0IjUrjOV1erffUInzEoR83di29zCjgNN3
UGIF6A+gUUiF2WEFVLoTBFpoEUj9d9DVjWVTh0GDS3vniEp+Y54yiZ2bWwh4riWC
KxxUOG8zUwKBgCZYcWvGsigyHDKE/hBOqvSawBCrFwcqZKyTaWVREc2TGCEsg6tS
oFULFzZ58P6rc6vQhIJUJ88bUH1pwrH6VBf2lwOQBebYuVgt60ykPjiQD6y/i/N3
39tUs5nhUFshUPQeLV6v9oMZt8j6fsftCnfH0O7oSXgjSrpeN0EbE+f9AoGAI4gH
1fcssUdAU62CVQLk61eGw9aoTOTyF5cTElHDfZQYyndgYgeNdp45usxhZNvKZDl7
McNFaUko8AMXsgeTvtj0a/fPYtg+GItnbt1OqSsTb1Z2giG1JJljJ2KxTuEzfSSy
yUkWVeT3SAwK4A1JQ1+BM+Kb8UFF4b2W7nc+kCECgYAfOOOasQEqszqL9w07gpML
Ohuh2z+d6RQWn5zQRBcHWPm6aSF0YvAN4rRdJtS7eS+Bq6D7cxMQwyNr8KdCLA1z
JEZReewjE+u0rN6aFFl5/IGhejlV2LMJ7tRW2jE+RZ2FKX1xGIeemlhfLmmJ/b2c
j9XLpu0FVZrAqZ0LIROzkQ==
-----END PRIVATE KEY-----
''';
