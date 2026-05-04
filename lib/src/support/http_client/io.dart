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

import 'dart:io' as io;

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;

import '../../exceptions.dart';
import '../../options.dart';
import '../certificate_pinning.dart';

http.Client createSdkHttpClient(NetworkOptions networkOptions) =>
    http_io.IOClient(createSdkIoHttpClient(networkOptions));

io.HttpClient createSdkIoHttpClient(NetworkOptions networkOptions) {
  final validator = CertificatePinValidator(networkOptions.certificatePinning);
  final client = io.HttpClient();
  if (!validator.isEnabled) {
    return client;
  }

  client.connectionFactory = _CertificatePinningConnectionFactory(validator).connect;
  return client;
}

class _CertificatePinningConnectionFactory {
  final CertificatePinValidator _validator;

  const _CertificatePinningConnectionFactory(this._validator);

  Future<io.ConnectionTask<io.Socket>> connect(
    Uri url,
    String? proxyHost,
    int? proxyPort,
  ) async {
    if (proxyHost != null || proxyPort != null) {
      throw UnsupportedError('Certificate pinning through HTTP proxies is not supported');
    }

    if (!_isTlsScheme(url.scheme)) {
      return io.Socket.startConnect(url.host, _portFor(url));
    }

    final rules = _validator.rulesForHost(url.host);
    final validateTrustedCertificate = rules.any((rule) => rule.hasTrustedCertificates);
    CertificatePinningException? trustedCertificateFailure;
    final task = await io.SecureSocket.startConnect(
      url.host,
      _portFor(url),
      context: validateTrustedCertificate ? io.SecurityContext(withTrustedRoots: false) : null,
      onBadCertificate: validateTrustedCertificate
          ? (certificate) {
              try {
                _validator.validateTrustedCertificate(
                  uri: url,
                  certificateDer: certificate.der,
                );
                return true;
              } on CertificatePinningException catch (error) {
                trustedCertificateFailure = error;
                return false;
              }
            }
          : null,
    );

    final socket = task.socket.catchError((Object error) {
      final failure = trustedCertificateFailure;
      if (failure != null) {
        throw failure;
      }
      throw error;
    }).then<io.Socket>((socket) {
      if (validateTrustedCertificate) {
        _validator.validateTrustedCertificate(
          uri: url,
          certificateDer: socket.peerCertificate?.der,
        );
      }
      _validator.validate(
        uri: url,
        certificateDer: socket.peerCertificate?.der,
      );
      return socket;
    });

    return io.ConnectionTask.fromSocket<io.Socket>(socket, task.cancel);
  }
}

bool _isTlsScheme(String scheme) => scheme == 'https' || scheme == 'wss';

int _portFor(Uri uri) {
  if (uri.hasPort) {
    return uri.port;
  }
  return _isTlsScheme(uri.scheme) ? 443 : 80;
}
