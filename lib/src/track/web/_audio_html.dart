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

import 'dart:html' as html;
import 'dart:js_util' as jsutil;

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '_audio_context.dart';

// ignore: implementation_imports
import 'package:dart_webrtc/src/media_stream_track_impl.dart'; // import_sorter: keep

const audioContainerId = 'livekit_audio_container';
const audioPrefix = 'livekit_audio_';

AudioContext _audioContext = AudioContext();
Map<String, html.Element> _audioElements = {};

Future<dynamic> startAudio(String id, rtc.MediaStreamTrack track) async {
  if (track is! MediaStreamTrackWeb) {
    return;
  }

  final elementId = audioPrefix + id;
  var audioElement = html.document.getElementById(elementId);
  if (audioElement == null) {
    audioElement = html.AudioElement()
      ..id = elementId
      ..autoplay = true;
    findOrCreateAudioContainer().append(audioElement);
    _audioElements[id] = audioElement;
  }

  if (audioElement is! html.AudioElement) {
    return;
  }
  final audioStream = html.MediaStream();
  audioStream.addTrack(track.jsTrack);
  audioElement.srcObject = audioStream;
  return audioElement.play();
}

Future<bool> startAllAudioElement() async {
  for (final element in _audioElements.values) {
    if (element is html.AudioElement) {
      await element.play();
    }
  }
  return _audioContext.state == AudioContextState.running;
}

void stopAudio(String id) {
  final audioElement = html.document.getElementById(audioPrefix + id);
  if (audioElement != null) {
    if (audioElement is html.AudioElement) {
      audioElement.srcObject = null;
    }
    _audioElements.remove(id);
    audioElement.remove();
  }
}

html.DivElement findOrCreateAudioContainer() {
  var div = html.document.getElementById(audioContainerId);
  if (div != null) {
    return div as html.DivElement;
  }

  div = html.DivElement();
  div.id = audioContainerId;
  div.style.display = 'none';
  html.document.body?.append(div);
  return div as html.DivElement;
}

void setSinkId(String id, String deviceId) {
  final audioElement = html.document.getElementById(audioPrefix + id);
  if (audioElement is html.AudioElement &&
      jsutil.hasProperty(audioElement, 'setSinkId')) {
    audioElement.setSinkId(deviceId);
  }
}
