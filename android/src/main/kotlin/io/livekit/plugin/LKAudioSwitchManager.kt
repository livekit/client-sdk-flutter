/*
 * Copyright 2026 LiveKit, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.livekit.plugin

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import com.twilio.audioswitch.AbstractAudioSwitch
import com.twilio.audioswitch.AudioDevice
import com.twilio.audioswitch.AudioSwitch
import com.twilio.audioswitch.CommDeviceAudioSwitch
import com.twilio.audioswitch.LegacyAudioSwitch

/**
 * Manages the Android platform audio session (audio mode, audio focus, and
 * output routing) for the LiveKit Flutter SDK, built on top of [AudioSwitch].
 *
 * This is LiveKit's own port of the audio-handling best practices from the
 * LiveKit Android SDK (`AudioSwitchHandler`) and flutter_webrtc
 * (`AudioSwitchManager`), so the Flutter SDK can own the platform audio session
 * directly instead of delegating to flutter_webrtc's native audio management.
 *
 * [AudioSwitch] is not thread-safe, so every interaction with it runs on a
 * single dedicated [HandlerThread].
 */
internal class LKAudioSwitchManager(private val context: Context) {
  // AudioSwitch is not threadsafe, so confine all access to a single long-lived
  // thread. The AudioSwitch instance is recreated per active session, while
  // queued lifecycle work stays serialized on this thread.
  private val thread = HandlerThread("LKAudioSwitchThread").also { it.start() }
  private val handler = Handler(thread.looper)

  private var audioSwitch: AbstractAudioSwitch? = null
  private var isActive = false

  // Configuration. Defaults mirror a communication/VoIP session and match the
  // AudioSwitchHandler defaults in the LiveKit Android SDK.
  private var manageAudioFocus = true
  private var audioMode = AudioManager.MODE_IN_COMMUNICATION
  private var focusMode = AudioManager.AUDIOFOCUS_GAIN
  private var audioStreamType = AudioManager.STREAM_VOICE_CALL
  private var audioAttributeUsageType = AudioAttributes.USAGE_VOICE_COMMUNICATION
  private var audioAttributeContentType = AudioAttributes.CONTENT_TYPE_SPEECH
  private var forceHandleAudioRouting = false

  private var speakerOutputPreferred = true
  private var speakerOutputForced = false

  /**
   * Apply an audio session configuration. Unspecified keys keep their current
   * value. When the session is already active, changes that only take effect at
   * activate() time trigger a deactivate and activate cycle so they apply live.
   */
  @Synchronized
  fun configure(configuration: Map<String, Any?>) {
    val previous = sessionConfigSnapshot()
    (configuration["manageAudioFocus"] as? Boolean)?.let { manageAudioFocus = it }
    audioModeForName(configuration["androidAudioMode"] as? String)?.let { audioMode = it }
    focusModeForName(configuration["androidAudioFocusMode"] as? String)?.let { focusMode = it }
    streamTypeForName(configuration["androidAudioStreamType"] as? String)?.let { audioStreamType = it }
    usageTypeForName(configuration["androidAudioAttributesUsageType"] as? String)?.let { audioAttributeUsageType = it }
    contentTypeForName(configuration["androidAudioAttributesContentType"] as? String)?.let { audioAttributeContentType = it }
    (configuration["forceHandleAudioRouting"] as? Boolean)?.let { forceHandleAudioRouting = it }
    val sessionConfig = sessionConfigSnapshot()
    val sessionConfigChanged = sessionConfig != previous
    val speakerRouting = speakerRoutingSnapshot()

    handler.post {
      val switch = audioSwitch ?: return@post
      applyConfiguration(switch, sessionConfig)
      // AudioSwitch applies the audio mode, focus, and attributes at activate()
      // time, so a live reconfiguration (e.g. communication to media) needs a
      // deactivate and activate cycle to take effect on an already active
      // session. Reassert speaker routing afterward.
      if (isActive && sessionConfigChanged) {
        switch.deactivate()
        switch.activate()
        applySpeakerRouting(switch, speakerRouting)
      }
    }
  }

  // Snapshot of the AudioSwitch properties applied only at activate() time, used
  // to detect when a live session needs a deactivate and activate cycle to pick
  // up a configuration change.
  private fun sessionConfigSnapshot() = SessionConfig(
    manageAudioFocus = manageAudioFocus,
    audioMode = audioMode,
    focusMode = focusMode,
    audioStreamType = audioStreamType,
    audioAttributeUsageType = audioAttributeUsageType,
    audioAttributeContentType = audioAttributeContentType,
    forceHandleAudioRouting = forceHandleAudioRouting,
  )

  /** Create (if needed) and activate the audio session: acquire focus, set mode and routing. */
  @Synchronized
  fun start() {
    val sessionConfig = sessionConfigSnapshot()
    val speakerRouting = speakerRoutingSnapshot()
    handler.post {
      val switch = audioSwitch ?: createSwitch(sessionConfig, speakerRouting).also { audioSwitch = it }
      if (!isActive) {
        switch.activate()
        applySpeakerRouting(switch, speakerRouting)
        isActive = true
      }
    }
  }

  /** Deactivate and tear down the audio session: release focus and restore the previous mode. */
  @Synchronized
  fun stop() {
    handler.post {
      audioSwitch?.stop()
      audioSwitch = null
      isActive = false
    }
  }

  /** Final cleanup when the plugin detaches. The manager must not be used after this. */
  @Synchronized
  fun dispose() {
    handler.post {
      audioSwitch?.stop()
      audioSwitch = null
      isActive = false
      thread.quitSafely()
    }
  }

  /**
   * Prefer routing to/from the speaker, letting a connected headset keep priority
   * unless [force] is true.
   */
  @Synchronized
  fun setSpeakerphoneOn(enable: Boolean, force: Boolean) {
    speakerOutputPreferred = enable
    speakerOutputForced = enable && force
    val speakerRouting = speakerRoutingSnapshot()
    handler.post {
      val switch = audioSwitch ?: return@post
      applySpeakerRouting(switch, speakerRouting)
    }
  }

  private fun createSwitch(
    sessionConfig: SessionConfig,
    speakerRouting: SpeakerRouting,
  ): AbstractAudioSwitch {
    val focusListener = AudioManager.OnAudioFocusChangeListener { }
    // API-aware switch selection, matching the LiveKit Android SDK's
    // AudioSwitchHandler: CommDeviceAudioSwitch uses the modern
    // AudioManager.setCommunicationDevice routing on API 31+.
    val switch = when {
      Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
        CommDeviceAudioSwitch(context, false, focusListener, speakerRouting.preferredDeviceList)

      Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
        AudioSwitch(context, false, focusListener, speakerRouting.preferredDeviceList)

      else ->
        LegacyAudioSwitch(context, false, focusListener, speakerRouting.preferredDeviceList)
    }
    applyConfiguration(switch, sessionConfig)
    switch.start { _, _ -> }
    return switch
  }

  private fun applyConfiguration(switch: AbstractAudioSwitch, sessionConfig: SessionConfig) {
    switch.manageAudioFocus = sessionConfig.manageAudioFocus
    switch.audioMode = sessionConfig.audioMode
    switch.focusMode = sessionConfig.focusMode
    switch.audioStreamType = sessionConfig.audioStreamType
    switch.audioAttributeUsageType = sessionConfig.audioAttributeUsageType
    switch.audioAttributeContentType = sessionConfig.audioAttributeContentType
    switch.forceHandleAudioRouting = sessionConfig.forceHandleAudioRouting
  }

  private fun applySpeakerRouting(switch: AbstractAudioSwitch, speakerRouting: SpeakerRouting) {
    // AudioSwitch treats selectDevice(null) as "select no device"; it does not
    // recompute the best route from the preferred-device list. Keep routing
    // automatic here so normal preference and forced-speaker priority both
    // follow device hot-plug changes without leaving a sticky selected device.
    switch.setPreferredDeviceList(speakerRouting.preferredDeviceList)
  }

  private fun speakerRoutingSnapshot() = SpeakerRouting(
    preferredDeviceList = preferredDeviceList(
      speakerOutputPreferred = speakerOutputPreferred,
      speakerOutputForced = speakerOutputForced,
    ),
  )

  private fun preferredDeviceList(
    speakerOutputPreferred: Boolean,
    speakerOutputForced: Boolean,
  ): List<Class<out AudioDevice>> =
    when {
      speakerOutputForced -> listOf(
        AudioDevice.Speakerphone::class.java,
        AudioDevice.BluetoothHeadset::class.java,
        AudioDevice.WiredHeadset::class.java,
        AudioDevice.Earpiece::class.java,
      )

      speakerOutputPreferred -> listOf(
        AudioDevice.BluetoothHeadset::class.java,
        AudioDevice.WiredHeadset::class.java,
        AudioDevice.Speakerphone::class.java,
        AudioDevice.Earpiece::class.java,
      )

      else -> listOf(
        AudioDevice.BluetoothHeadset::class.java,
        AudioDevice.WiredHeadset::class.java,
        AudioDevice.Earpiece::class.java,
        AudioDevice.Speakerphone::class.java,
      )
    }

  private data class SessionConfig(
    val manageAudioFocus: Boolean,
    val audioMode: Int,
    val focusMode: Int,
    val audioStreamType: Int,
    val audioAttributeUsageType: Int,
    val audioAttributeContentType: Int,
    val forceHandleAudioRouting: Boolean,
  )

  private data class SpeakerRouting(
    val preferredDeviceList: List<Class<out AudioDevice>>,
  )
}

// Map the Flutter-side enum names (see android_audio_session_adapter.dart) to
// Android framework constants. Ported from flutter_webrtc's AudioUtils.

private fun audioModeForName(name: String?): Int? = when (name) {
  null -> null
  "normal" -> AudioManager.MODE_NORMAL
  "callScreening" -> AudioManager.MODE_CALL_SCREENING
  "inCall" -> AudioManager.MODE_IN_CALL
  "inCommunication" -> AudioManager.MODE_IN_COMMUNICATION
  "ringtone" -> AudioManager.MODE_RINGTONE
  else -> null
}

private fun focusModeForName(name: String?): Int? = when (name) {
  null -> null
  "gain" -> AudioManager.AUDIOFOCUS_GAIN
  "gainTransient" -> AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
  "gainTransientExclusive" -> AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE
  "gainTransientMayDuck" -> AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
  else -> null
}

private fun streamTypeForName(name: String?): Int? = when (name) {
  null -> null
  "accessibility" -> AudioManager.STREAM_ACCESSIBILITY
  "alarm" -> AudioManager.STREAM_ALARM
  "dtmf" -> AudioManager.STREAM_DTMF
  "music" -> AudioManager.STREAM_MUSIC
  "notification" -> AudioManager.STREAM_NOTIFICATION
  "ring" -> AudioManager.STREAM_RING
  "system" -> AudioManager.STREAM_SYSTEM
  "voiceCall" -> AudioManager.STREAM_VOICE_CALL
  else -> null
}

private fun usageTypeForName(name: String?): Int? = when (name) {
  null -> null
  "alarm" -> AudioAttributes.USAGE_ALARM
  "assistanceAccessibility" -> AudioAttributes.USAGE_ASSISTANCE_ACCESSIBILITY
  "assistanceNavigationGuidance" -> AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE
  "assistanceSonification" -> AudioAttributes.USAGE_ASSISTANCE_SONIFICATION
  "assistant" -> AudioAttributes.USAGE_ASSISTANT
  "game" -> AudioAttributes.USAGE_GAME
  "media" -> AudioAttributes.USAGE_MEDIA
  "notification" -> AudioAttributes.USAGE_NOTIFICATION
  "notificationEvent" -> AudioAttributes.USAGE_NOTIFICATION_EVENT
  "notificationRingtone" -> AudioAttributes.USAGE_NOTIFICATION_RINGTONE
  "unknown" -> AudioAttributes.USAGE_UNKNOWN
  "voiceCommunication" -> AudioAttributes.USAGE_VOICE_COMMUNICATION
  "voiceCommunicationSignalling" -> AudioAttributes.USAGE_VOICE_COMMUNICATION_SIGNALLING
  else -> null
}

private fun contentTypeForName(name: String?): Int? = when (name) {
  null -> null
  "movie" -> AudioAttributes.CONTENT_TYPE_MOVIE
  "music" -> AudioAttributes.CONTENT_TYPE_MUSIC
  "sonification" -> AudioAttributes.CONTENT_TYPE_SONIFICATION
  "speech" -> AudioAttributes.CONTENT_TYPE_SPEECH
  "unknown" -> AudioAttributes.CONTENT_TYPE_UNKNOWN
  else -> null
}
