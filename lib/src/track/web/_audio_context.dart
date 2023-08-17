// Copyright 2023 LiveKit, Inc.
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

import 'dart:js_util' as jsutil;

import 'package:js/js.dart';

@JS()
external dynamic get undefined;

enum AudioContextState {
  suspended('suspended'),
  running('running'),
  closed('closed');

  final String value;
  static AudioContextState fromValue(String value) =>
      values.firstWhere((e) => e.value == value);
  static Iterable<AudioContextState> fromValues(Iterable<String> values) =>
      values.map(fromValue);
  const AudioContextState(this.value);
}

@anonymous
@JS()
@staticInterop
class AudioContextOptions {
  external factory AudioContextOptions(
      {dynamic latencyHint, double? sampleRate});
}

@JS()
@staticInterop
class AudioContext {
  external factory AudioContext._([AudioContextOptions? contextOptions]);

  factory AudioContext([AudioContextOptions? contextOptions]) =>
      AudioContext._(contextOptions ?? undefined);
}

extension PropsBaseAudioContext on AudioContext {
  AudioContextState get state =>
      AudioContextState.fromValue(jsutil.getProperty(this, 'state'));
}
