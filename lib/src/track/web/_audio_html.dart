import 'dart:html' as html;
import 'dart:js_util' as jsutil;

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:js_bindings/js_bindings.dart' as js_bindings;

// ignore: implementation_imports
import 'package:dart_webrtc/src/media_stream_track_impl.dart'; // import_sorter: keep

const audioContainerId = 'livekit_audio_container';
const audioPrefix = 'livekit_audio_';

js_bindings.AudioContext _audioContext = js_bindings.AudioContext();
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
  return _audioContext.state == js_bindings.AudioContextState.running;
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
