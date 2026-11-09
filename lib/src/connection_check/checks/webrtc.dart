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

import 'package:meta/meta.dart';

import '../../internal/events.dart';
import '../../logger.dart';
import 'checker.dart';

/// Verifies that a WebRTC (peer) connection to the LiveKit server can be
/// established, and inspects the ICE candidates provided by the server.
class WebRTCCheck extends Checker {
  WebRTCCheck(super.url, super.token, {super.options, super.room});

  @override
  String get description => 'Establishing WebRTC connection';

  @override
  Future<void> perform() async {
    var hasTcp = false;
    var hasIpv4Udp = false;

    // Observe the ICE candidates trickled by the server over the signal
    // connection (equivalent of hooking `onTrickle` in client-sdk-js).
    final signalListener = engine.signalClient.createListener();
    signalListener.on<SignalTrickleEvent>((event) {
      final candidate = parseIceCandidate(event.candidate.candidate ?? '');
      if (candidate == null) {
        return;
      }
      var str = '${candidate.protocol} ${candidate.address}:${candidate.port} ${candidate.type}';
      if (isIpPrivate(candidate.address)) {
        str += ' (private)';
      } else {
        if (candidate.protocol == 'tcp' && candidate.tcpType == 'passive') {
          hasTcp = true;
          str += ' (passive)';
        } else if (candidate.protocol == 'udp') {
          hasIpv4Udp = true;
        }
      }
      appendMessage(str);
    });

    try {
      await connect();
      logger.fine('now the room is connected');
    } catch (err) {
      appendWarning('ports need to be open on firewall in order to connect.');
      rethrow;
    } finally {
      await signalListener.dispose();
    }
    if (!hasTcp) {
      appendWarning('Server is not configured for ICE/TCP');
    }
    if (!hasIpv4Udp) {
      appendWarning('No public IPv4 UDP candidates were found. Your server is likely not configured correctly');
    }
  }
}

/// Parsed representation of an ICE candidate attribute (RFC 5245
/// `candidate:` line).
@visibleForTesting
class ParsedIceCandidate {
  const ParsedIceCandidate({
    required this.protocol,
    required this.address,
    required this.port,
    required this.type,
    this.tcpType,
  });

  /// Transport protocol, `udp` or `tcp`.
  final String protocol;

  final String address;

  final int port;

  /// Candidate type: `host`, `srflx`, `prflx` or `relay`.
  final String type;

  /// TCP candidate type: `active`, `passive` or `so`.
  final String? tcpType;
}

/// Parses an ICE candidate attribute line, returns null if [sdp] is not a
/// valid candidate line.
@visibleForTesting
ParsedIceCandidate? parseIceCandidate(String sdp) {
  var line = sdp.trim();
  if (line.startsWith('a=')) {
    line = line.substring(2);
  }
  if (line.startsWith('candidate:')) {
    line = line.substring('candidate:'.length);
  }
  final parts = line.split(RegExp(r'\s+'));
  if (parts.length < 8 || parts[6] != 'typ') {
    return null;
  }
  final port = int.tryParse(parts[5]);
  if (port == null) {
    return null;
  }
  String? tcpType;
  for (var i = 8; i + 1 < parts.length; i += 2) {
    if (parts[i] == 'tcptype') {
      tcpType = parts[i + 1];
    }
  }
  return ParsedIceCandidate(
    protocol: parts[2].toLowerCase(),
    address: parts[4],
    port: port,
    type: parts[7],
    tcpType: tcpType,
  );
}

/// True if [address] is in a private IPv4 range.
@visibleForTesting
bool isIpPrivate(String address) {
  final parts = address.split('.');
  if (parts.length == 4) {
    if (parts[0] == '10') {
      return true;
    } else if (parts[0] == '192' && parts[1] == '168') {
      return true;
    } else if (parts[0] == '172') {
      final second = int.tryParse(parts[1]);
      if (second != null && second >= 16 && second <= 31) {
        return true;
      }
    }
  }
  return false;
}
