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
import 'package:livekit_client/src/support/http_client/io.dart';
import 'package:livekit_client/src/support/websocket.dart';

const _testServerHost = '127.0.0.1';

void main() {
  test('rejects exact pinned leaf certificates without trusted certificates', () async {
    final server = await _TlsTestServer.start();
    addTearDown(server.close);

    await expectLater(
      sdkHttpGet(
        Uri.parse('https://$_testServerHost:${server.port}/settings'),
        networkOptions: NetworkOptions(
          certificatePinning: CertificatePinningOptions(
            rules: [
              CertificatePinningRule(
                hosts: const [_testServerHost],
                pinnedLeafCertificates: [CertificateBytes.pem(_pemBytes(_localhostCertificatePem))],
              ),
            ],
          ),
        ),
      ),
      throwsA(isA<io.HandshakeException>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(server.receivedBytes, isEmpty);
  });

  test('allows exact pinned leaf certificates with trusted leaf certificate stores', () async {
    final server = await _TlsTestServer.start();
    addTearDown(server.close);

    final response = await sdkHttpGet(
      Uri.parse('https://$_testServerHost:${server.port}/settings'),
      networkOptions: NetworkOptions(
        certificatePinning: CertificatePinningOptions(
          rules: [
            CertificatePinningRule(
              hosts: const [_testServerHost],
              pinnedLeafCertificates: [CertificateBytes.pem(_pemBytes(_localhostCertificatePem))],
              trustedCertificates: [CertificateBytes.pem(_pemBytes(_localhostCertificatePem))],
            ),
          ],
        ),
      ),
    );

    expect(response.statusCode, 200);
    expect(response.body, 'OK');
    expect(server.receivedText, contains('GET /settings HTTP/1.1'));
  });

  test('allows trusted leaf certificate stores without SPKI pins', () async {
    final server = await _TlsTestServer.start();
    addTearDown(server.close);

    final response = await sdkHttpGet(
      Uri.parse('https://$_testServerHost:${server.port}/settings'),
      networkOptions: NetworkOptions(
        certificatePinning: CertificatePinningOptions(
          rules: [
            CertificatePinningRule(
              hosts: const [_testServerHost],
              trustedCertificates: [CertificateBytes.pem(_pemBytes(_localhostCertificatePem))],
            ),
          ],
        ),
      ),
    );

    expect(response.statusCode, 200);
    expect(response.body, 'OK');
    expect(server.receivedText, contains('GET /settings HTTP/1.1'));
  });

  test('allows trusted CA certificate stores without SPKI pins', () async {
    final server = await _TlsTestServer.start();
    addTearDown(server.close);

    final response = await sdkHttpGet(
      Uri.parse('https://$_testServerHost:${server.port}/settings'),
      networkOptions: NetworkOptions(
        certificatePinning: CertificatePinningOptions(
          rules: [
            CertificatePinningRule(
              hosts: const [_testServerHost],
              trustedCertificates: [CertificateBytes.pem(_pemBytes(_trustedCaCertificatePem))],
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
        Uri.parse('https://$_testServerHost:${server.port}/rtc'),
        headers: const {'Authorization': 'Bearer token'},
        networkOptions: NetworkOptions(
          certificatePinning: CertificatePinningOptions(
            rules: [
              CertificatePinningRule(
                hosts: const [_testServerHost],
                primaryPins: const ['sha256/not-the-presented-pin'],
                pinnedLeafCertificates: [CertificateBytes.pem(_pemBytes(_localhostCertificatePem))],
                trustedCertificates: [CertificateBytes.pem(_pemBytes(_localhostCertificatePem))],
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

  test('validates SPKI pins with trusted stores before sending HTTP request bytes', () async {
    final server = await _TlsTestServer.start();
    addTearDown(server.close);

    await expectLater(
      sdkHttpGet(
        Uri.parse('https://$_testServerHost:${server.port}/rtc'),
        headers: const {'Authorization': 'Bearer token'},
        networkOptions: NetworkOptions(
          certificatePinning: CertificatePinningOptions(
            rules: [
              CertificatePinningRule(
                hosts: const [_testServerHost],
                primaryPins: const ['sha256/not-the-presented-pin'],
                trustedCertificates: [CertificateBytes.pem(_pemBytes(_trustedCaCertificatePem))],
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
        Uri.parse('wss://$_testServerHost:${server.port}/rtc'),
        headers: const {'Authorization': 'Bearer token'},
        networkOptions: NetworkOptions(
          certificatePinning: CertificatePinningOptions(
            rules: [
              CertificatePinningRule(
                hosts: const [_testServerHost],
                primaryPins: const ['sha256/not-the-presented-pin'],
                pinnedLeafCertificates: [CertificateBytes.pem(_pemBytes(_localhostCertificatePem))],
                trustedCertificates: [CertificateBytes.pem(_pemBytes(_localhostCertificatePem))],
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

  test('allows matching pinned leaf certificates and SPKI pins together', () async {
    final server = await _TlsTestServer.start();
    addTearDown(server.close);

    final response = await sdkHttpGet(
      Uri.parse('https://$_testServerHost:${server.port}/rtc'),
      headers: const {'Authorization': 'Bearer token'},
      networkOptions: NetworkOptions(
        certificatePinning: CertificatePinningOptions(
          rules: [
            CertificatePinningRule(
              hosts: const [_testServerHost],
              primaryPins: [certificateSpkiSha256Pin(_certificateDerFromPem(_localhostCertificatePem))],
              pinnedLeafCertificates: [CertificateBytes.pem(_pemBytes(_localhostCertificatePem))],
              trustedCertificates: [CertificateBytes.pem(_pemBytes(_trustedCaCertificatePem))],
            ),
          ],
        ),
      ),
    );

    expect(response.statusCode, 200);
    expect(server.receivedText, contains('authorization: Bearer token'));
  });

  test('allows matching trusted certificate stores and SPKI pins together', () async {
    final server = await _TlsTestServer.start();
    addTearDown(server.close);

    final response = await sdkHttpGet(
      Uri.parse('https://$_testServerHost:${server.port}/rtc'),
      headers: const {'Authorization': 'Bearer token'},
      networkOptions: NetworkOptions(
        certificatePinning: CertificatePinningOptions(
          rules: [
            CertificatePinningRule(
              hosts: const [_testServerHost],
              primaryPins: [certificateSpkiSha256Pin(_certificateDerFromPem(_localhostCertificatePem))],
              trustedCertificates: [CertificateBytes.pem(_pemBytes(_trustedCaCertificatePem))],
            ),
          ],
        ),
      ),
    );

    expect(response.statusCode, 200);
    expect(server.receivedText, contains('authorization: Bearer token'));
  });

  test('allows HTTP proxies when no pinning rule applies to the target', () async {
    final proxy = await _PlainHttpProxyServer.start();
    addTearDown(proxy.close);

    final client = createSdkIoHttpClient(const NetworkOptions(
      certificatePinning: CertificatePinningOptions(
        rules: [
          CertificatePinningRule(
            hosts: ['pinned.example.com'],
            primaryPins: ['sha256/not-the-presented-pin'],
          ),
        ],
      ),
    ));
    addTearDown(() => client.close(force: true));

    client.findProxy = (_) => 'PROXY $_testServerHost:${proxy.port}';

    final request = await client.getUrl(
      Uri.parse('http://127.0.0.2:${proxy.port}/settings'),
    );
    final response = await request.close();
    final body = await utf8.decodeStream(response);

    expect(response.statusCode, 200);
    expect(body, 'OK');
    expect(proxy.receivedText, contains('GET http://127.0.0.2:${proxy.port}/settings HTTP/1.1'));
  });

  test('rejects HTTP proxies when TLS pinning applies to the target', () async {
    final proxy = await _PlainHttpProxyServer.start();
    addTearDown(proxy.close);

    final client = createSdkIoHttpClient(const NetworkOptions(
      certificatePinning: CertificatePinningOptions(
        rules: [
          CertificatePinningRule(
            hosts: [_testServerHost],
            primaryPins: ['sha256/not-the-presented-pin'],
          ),
        ],
      ),
    ));
    addTearDown(() => client.close(force: true));

    client.findProxy = (_) => 'PROXY $_testServerHost:${proxy.port}';

    await expectLater(
      () async {
        final request = await client.getUrl(Uri.parse('https://$_testServerHost/settings'));
        await request.close();
      }(),
      throwsA(isA<UnsupportedError>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(proxy.receivedBytes, isEmpty);
  });
}

class _PlainHttpProxyServer {
  final io.ServerSocket _server;
  final _receivedBytes = <int>[];
  final _sockets = <io.Socket>[];
  late final StreamSubscription<io.Socket> _subscription;

  _PlainHttpProxyServer._(this._server) {
    _subscription = _server.listen(_handleSocket);
  }

  int get port => _server.port;

  List<int> get receivedBytes => List.unmodifiable(_receivedBytes);

  String get receivedText => ascii.decode(_receivedBytes, allowInvalid: true);

  static Future<_PlainHttpProxyServer> start() async {
    final server = await io.ServerSocket.bind(
      io.InternetAddress.loopbackIPv4,
      0,
    );
    return _PlainHttpProxyServer._(server);
  }

  Future<void> close() async {
    await _subscription.cancel();
    for (final socket in _sockets) {
      socket.destroy();
    }
    await _server.close();
  }

  void _handleSocket(io.Socket socket) {
    _sockets.add(socket);
    socket.listen((data) {
      _receivedBytes.addAll(data);
      if (receivedText.contains('\r\n\r\n')) {
        socket.add(ascii.encode('HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK'));
        unawaited(socket.flush().then((_) => socket.close()));
      }
    });
  }
}

class _TlsTestServer {
  final io.SecureServerSocket _server;
  final _connected = Completer<void>();
  final _receivedBytes = <int>[];
  final _sockets = <io.SecureSocket>[];
  late final StreamSubscription<io.SecureSocket> _subscription;

  _TlsTestServer._(this._server) {
    _subscription = _server.listen(_handleSocket, onError: (_) {});
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

const _trustedCaCertificatePem = '''
-----BEGIN CERTIFICATE-----
MIIDojCCAoqgAwIBAgIUXrZwbSCNTAZ2+2lUbPTSb9dYaJIwDQYJKoZIhvcNAQEL
BQAwVzELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRAwDgYDVQQKDAdMaXZlS2l0
MQ0wCwYDVQQLDARUZXN0MRowGAYDVQQDDBFMaXZlS2l0IFRlc3QgQ0EgNjAeFw0y
NjA1MDUwMjA0MjdaFw0yNzA1MDUwMjA0MjdaMFcxCzAJBgNVBAYTAlVTMQswCQYD
VQQIDAJDQTEQMA4GA1UECgwHTGl2ZUtpdDENMAsGA1UECwwEVGVzdDEaMBgGA1UE
AwwRTGl2ZUtpdCBUZXN0IENBIDYwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQDLS6cQd3FuzOj88FQqIlXndmjhgXhGDiCipj1jEZ4MgVR3cbm+FfwEL2KC
TOLTJpBmMGL5DyRGHFZjD/+h3IxRGeO2nlAn8o2lVoXvCWfJfZMkZN9660oWGQDr
+HM3TmoQqAkwBnTynv3embsgOGhhtBQ9FADa1x4KeNU4NRUQQbCDDuU1wPcS+3Rd
/LgJOtfMG+tD6ACEaYV/SskHxASxEVPL4kpxzgNSGju4Hyo/v1bA9jvMCgFcp951
YQ9nkVreNpbIQ3N8exfTVFPrh0aWtg7RM52SQ1bVZP0/y3yMV4UqJwus0wzNNza4
89PBnZ4yVqr13zNGWRzXXJx4hNjtAgMBAAGjZjBkMBIGA1UdEwEB/wQIMAYBAf8C
AQEwDgYDVR0PAQH/BAQDAgGGMB0GA1UdDgQWBBSD7seTcG6sMU5MYiZJH1hXZzMD
vjAfBgNVHSMEGDAWgBSD7seTcG6sMU5MYiZJH1hXZzMDvjANBgkqhkiG9w0BAQsF
AAOCAQEAfM6fhcnDnNAenSkX2Bj4y0G3gYD5yvJykmE5uBbLB1sCteott1bqCAI0
rWwWthtrMqOgIy+E3AWRD5Dbh/RutrCKvM+bwWI6nuOTxKyD0Eg4Q7LJci6kBaZP
uHfu4D+4hQUbPVZu9MEzd4h7VV21goLs/Toj772NY5gsgNGT1ZEaSdalvtm2Aprq
Bht1zaNWX64rpTVlj4EInRMtXXoJym+KWx9UGzXSuEffCko3Bjyj7XxDpLHjCe3t
xHbBuvt8/X9G6LmM2XHenHs3R8fE+MR+q+J7+ydc5iYe/TF5so2l5k6OPMDASdaw
tx3DB1buXwYfqvJMfxUHHDcBB9fh1Q==
-----END CERTIFICATE-----
''';

const _localhostCertificatePem = '''
-----BEGIN CERTIFICATE-----
MIIDxzCCAq+gAwIBAgIUGhRL7309IUNTm6hvItsQIT62H2gwDQYJKoZIhvcNAQEL
BQAwVzELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRAwDgYDVQQKDAdMaXZlS2l0
MQ0wCwYDVQQLDARUZXN0MRowGAYDVQQDDBFMaXZlS2l0IFRlc3QgQ0EgNjAeFw0y
NjA1MDUwMjA0MzNaFw0yNzA1MDUwMjA0MzNaME8xCzAJBgNVBAYTAlVTMQswCQYD
VQQIDAJDQTEQMA4GA1UECgwHTGl2ZUtpdDENMAsGA1UECwwEVGVzdDESMBAGA1UE
AwwJbG9jYWxob3N0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvYrq
bAiPJeD0XiRzQ5R1sc5nXAkD0H/OetANRi/UzLu7CxyjhqUltGxKuIHLBdDi/s7Y
EYB2rb3ZP83NDVrgwaQo0doMcDg75DxT4/XgLst9yqAVH85UvvKC/RqR4TUtjZm8
omKma7/E8DBk7fswydWigMV9x/xMZmPi3v+U9oTo20xrx33z14DhMS8H5VqAoLf8
cHJRiRv/LU69ZWzSxjRSYlQS95/KmmfWYdEAu+oDmhEBtQ5ipD/7GeUt7QcziGyU
SBrma62Oun6m60UABR4DoMpJh2dhfmEaTF5owYpw5UpwIDDNDecrncbShe/TJGb7
b4Q4PwRbuhKR4IfyiQIDAQABo4GSMIGPMBoGA1UdEQQTMBGCCWxvY2FsaG9zdIcE
fwAAATAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMBMA4GA1UdDwEB
/wQEAwIFoDAdBgNVHQ4EFgQUuGJ7ZDy7LJqU1pk1gC8ml05KgWcwHwYDVR0jBBgw
FoAUg+7Hk3BurDFOTGImSR9YV2czA74wDQYJKoZIhvcNAQELBQADggEBAELuskBJ
vmvmtwVgQBjV+XP5cMAo9K0niLEtiSTVbIb82Zn8td5paIHLtdCUWo47FsXGcEka
xjHF7F+c+xSmLcmyscwIoueMlMznCMV9pd2Q9VKbGt/2H/YJKFkq151l3+DVrRNN
CxyX1bjWBvpPpwVVVtz9Ydrp5Uvmzd4IrtYJRz/Ty62y2YKmqEVmsfBqBvdxbF5R
/3Ss8AN3k/+SeRj2LFDg+0ekEAkzx08wG2Zhoj6kS98fldpao90JCOiSEn2DHcv6
jOt2XQ4kR0oSVkU+KyVyGtMhNjjQnWjJOuVpo/rdhtEKz4/9B4ofKYgoaeATqoQg
Jioy3puXYIMud+Y=
-----END CERTIFICATE-----
''';

const _localhostPrivateKeyPem = '''
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC9iupsCI8l4PRe
JHNDlHWxzmdcCQPQf8560A1GL9TMu7sLHKOGpSW0bEq4gcsF0OL+ztgRgHatvdk/
zc0NWuDBpCjR2gxwODvkPFPj9eAuy33KoBUfzlS+8oL9GpHhNS2NmbyiYqZrv8Tw
MGTt+zDJ1aKAxX3H/ExmY+Le/5T2hOjbTGvHffPXgOExLwflWoCgt/xwclGJG/8t
Tr1lbNLGNFJiVBL3n8qaZ9Zh0QC76gOaEQG1DmKkP/sZ5S3tBzOIbJRIGuZrrY66
fqbrRQAFHgOgykmHZ2F+YRpMXmjBinDlSnAgMM0N5yudxtKF79MkZvtvhDg/BFu6
EpHgh/KJAgMBAAECggEACWn34KvAKFp26KIY03dxLQaaXZjZBqcCY1kn/59qi0yb
qp6ehJZ5O+/Q+j8ADWblj1BIrP3bZx+xxZh8IbisxxFXMa0Jxx0T5G8Wn5DbtJdI
xSKUSgMedGlpFhcWvb+9ZnYHR21s5Jceues9aBB8yNmCe7DTYXZneQJnBzpcdK3p
QH5h+w5H3Eol9aT0omaOcuJNUGW1YtOBHyiJT0HIccI4rwBr++E/w/WjNoAghuFK
RDQEs4kj8uj3A85QfFZSwAlYO6kPKaqvGKglLzinrmW5aj98FGufzUWLoI2MPPhK
5yDBbgD052Coql0TgvDFItHAXtSLt4WX2Wgi0dL0zQKBgQDzvBlbgJgtYgBW4CdO
Sy6XaDkSJBRAXbZtqUbOvXKpzF2BBbBA8cXhZF9vFrQJQf8+rh+c+OuCzdMqtvBc
BGOnb3A0RouyKaSrrXJgJjcMnKueB/opcEUAKxpEzF0+Jg6CiJDuGyQ7KbrVqIfR
tu8fhIlb5V6ttBWEJLVd3jLU7wKBgQDHFLB4X2pN2K1FhAA7Q+Eg3naQHMiS5aT2
hs+BMa7WqtLt5MWPxv4yGgCaj6rss2xeuANBEE1ijAfV6PJwBON7PRPyw2eALM/O
k1wyDnIoBQDsFmwPHBzHVxpn200oNQrYTsCK2OWlcsv9AUyyoYWcdJ43wcHt8uGt
vhriiF3gBwKBgCetrn8b7yosMxvxf9SaHqqdV/UhFH7qAqHVleZgJwOHdo1jjK71
7R3lRjgCfSqoqNHebN0UFNsFgOQKRhTkzgha9uw7s9A8QUeFhAItFnciJjoi2FHY
qhL98VfT4TYV4fTUIKvylTJgd78CoaG9Yy5BWE8yhvhGQd5yT2hJnQLXAoGAR0eA
G8lF/ZNsDqzBjHa0X5lnaBf2NKpmkyIXn9FTIWdOWIEFv4HnN7cZqj1wXImtboiC
GcSlgHhUweFDFJqbfF+VCeGu6DSjPvqCEyYa93s7Jkys6ggNwc3NFYxupsu/E023
IL+iEcf1g6P4eyjb9vXGRH5qWjERXqznYV6kBfcCgYAnl/r8/ysuIuiUQ9d1CMAq
F6n8iC9IWl51SvrZZV85FgsR2MifmajE9AxiDHlROK5Cx0hWdDUEqkNXOX4iEhNW
aUeJreqbZQNpNjs5DeG2PydwP0anBkQKr3T0g4Uwt+CdRo1qBvX0uNprgthbsKy0
R86q1fzRj1MGMGbJ/r6Xeg==
-----END PRIVATE KEY-----
''';
