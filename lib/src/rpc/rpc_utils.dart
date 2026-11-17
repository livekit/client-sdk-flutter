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

import 'package:meta/meta.dart';

/// The number of bytes [s] occupies once encoded as UTF-8.
@internal
int byteLength(String s) => utf8.encode(s).length;

/// Truncates [s] so that its UTF-8 encoding fits within [maxBytes].
///
/// Dart strings are counted in UTF-16 code units, which is not the unit the wire
/// budget is expressed in, so the cut point is found by binary search over the
/// encoded length rather than by slicing at [maxBytes] directly.
@internal
String truncateBytes(String s, int maxBytes) {
  if (byteLength(s) <= maxBytes) {
    return s;
  }

  var low = 0;
  var high = s.length;

  // Binary search for the longest prefix that fits.
  while (low < high) {
    final mid = (low + high + 1) ~/ 2;
    if (byteLength(s.substring(0, mid)) <= maxBytes) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }

  // Never end on the first half of a surrogate pair: it would be encoded as a
  // replacement character, and the truncated string would no longer round trip.
  if (low > 0 && _isHighSurrogate(s.codeUnitAt(low - 1))) {
    low -= 1;
  }

  return s.substring(0, low);
}

bool _isHighSurrogate(int codeUnit) => codeUnit >= 0xd800 && codeUnit <= 0xdbff;
