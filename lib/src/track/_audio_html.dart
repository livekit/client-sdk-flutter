// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter_webrtc/flutter_webrtc.dart';
// ignore: implementation_imports
import 'package:flutter_webrtc/src/web/media_stream_track_impl.dart';

const audioContainerId = 'livekit_audio_container';
const audioPrefix = 'livekit_audio_';

void startAudio(String id, MediaStreamTrack track) {
  if (track is! MediaStreamTrackWeb) {
    return;
  }
  var elementId = audioPrefix + id;
  var audioElement = html.document.getElementById(elementId);
  if (audioElement == null) {
    audioElement = html.AudioElement()
      ..id = elementId
      ..autoplay = true;
    findOrCreateAudioContainer().append(audioElement);
  }

  if (audioElement is! html.AudioElement) {
    return;
  }
  var audioStream = html.MediaStream();
  audioStream.addTrack(track.jsTrack);
  audioElement.srcObject = audioStream;
}

void stopAudio(String id) {
  var audioElement = html.document.getElementById(audioPrefix + id);
  if (audioElement != null) {
    if (audioElement is html.AudioElement) {
      audioElement.srcObject = null;
    }
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
