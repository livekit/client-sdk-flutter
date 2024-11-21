package io.livekit.plugin

import org.webrtc.AudioTrackSink

interface LKAudioTrack {

    fun addSink(sink: AudioTrackSink?)

    fun removeSink(sink: AudioTrackSink)

    fun id(): String
}