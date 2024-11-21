package io.livekit.plugin

import com.cloudwebrtc.webrtc.audio.LocalAudioTrack
import org.webrtc.AudioTrackSink

class LKLocalAudioTrack : LKAudioTrack {
    private var localAudioTrack: LocalAudioTrack? = null

    constructor(localAudioTrack: LocalAudioTrack) {
        this.localAudioTrack = localAudioTrack
    }

    override fun addSink(sink: AudioTrackSink?) {
        localAudioTrack?.addSink(sink)
    }

    override fun removeSink(sink: AudioTrackSink) {
        localAudioTrack?.removeSink(sink)
    }

    override fun id(): String {
        return localAudioTrack?.id() ?: ""
    }
}