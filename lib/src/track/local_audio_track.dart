import '../imports.dart';

class LocalAudioTrack extends AudioTrack {
  LocalAudioTrack(
    String name,
    MediaStreamTrack track,
    MediaStream stream,
  ) : super(name, track, stream);

  /// Creates a new audio track from the default audio input device.
  static Future<LocalAudioTrack> createTrack([LocalAudioTrackOptions? options]) async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia(<String, dynamic>{
        'audio': true,
        'video': false,
      });

      if (stream.getAudioTracks().isEmpty) {
        return Future.error(TrackCreateError());
      }

      return LocalAudioTrack('', stream.getAudioTracks().first, stream);
    } catch (e) {
      return Future.error(e);
    }
  }
}
