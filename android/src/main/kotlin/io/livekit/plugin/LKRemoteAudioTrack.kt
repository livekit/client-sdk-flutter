package io.livekit.plugin

import org.webrtc.AudioTrack
import org.webrtc.AudioTrackSink

class LKRemoteAudioTrack: LKAudioTrack {
    private var audioTrack: AudioTrack? = null

    constructor(
        audioTrack: AudioTrack
    ) {
        this.audioTrack = audioTrack
    }

    override fun addSink(sink: AudioTrackSink?) {
        audioTrack?.addSink(sink)
    }

    override fun removeSink(sink: AudioTrackSink) {
        audioTrack?.removeSink(sink)
    }

    override fun id(): String {
        return audioTrack?.id() ?: ""
    }
}