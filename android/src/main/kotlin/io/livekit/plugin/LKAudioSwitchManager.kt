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
 * Manages the Android platform audio session — audio mode, audio focus, and
 * output routing — for the LiveKit Flutter SDK, built on top of [AudioSwitch].
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

  private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

  // AudioSwitch is not threadsafe; confine all access to a single thread.
  private var thread: HandlerThread? = null
  private var handler: Handler? = null

  private var audioSwitch: AbstractAudioSwitch? = null
  private var isActive = false

  // Configuration. Defaults mirror a communication/VoIP session and match the
  // AudioSwitchHandler defaults in the LiveKit Android SDK.
  private val loggingEnabled = false
  private var manageAudioFocus = true
  private var audioMode = AudioManager.MODE_IN_COMMUNICATION
  private var focusMode = AudioManager.AUDIOFOCUS_GAIN
  private var audioStreamType = AudioManager.STREAM_VOICE_CALL
  private var audioAttributeUsageType = AudioAttributes.USAGE_VOICE_COMMUNICATION
  private var audioAttributeContentType = AudioAttributes.CONTENT_TYPE_SPEECH
  private var forceHandleAudioRouting = false

  private var preferredDeviceList = preferredDeviceList(speakerFirst = true)

  /**
   * Apply an audio session configuration. Unspecified keys keep their current
   * value. Changes are applied to a running [AudioSwitch] without a restart.
   */
  @Synchronized
  fun configure(configuration: Map<String, Any?>) {
    (configuration["manageAudioFocus"] as? Boolean)?.let { manageAudioFocus = it }
    audioModeForName(configuration["androidAudioMode"] as? String)?.let { audioMode = it }
    focusModeForName(configuration["androidAudioFocusMode"] as? String)?.let { focusMode = it }
    streamTypeForName(configuration["androidAudioStreamType"] as? String)?.let { audioStreamType = it }
    usageTypeForName(configuration["androidAudioAttributesUsageType"] as? String)?.let { audioAttributeUsageType = it }
    contentTypeForName(configuration["androidAudioAttributesContentType"] as? String)?.let { audioAttributeContentType = it }
    (configuration["forceHandleAudioRouting"] as? Boolean)?.let { forceHandleAudioRouting = it }

    // Apply to a live switch so reconfiguration (e.g. communication -> media)
    // does not require a restart. No-op until the switch exists.
    handler?.post { audioSwitch?.let { applyConfiguration(it) } }
  }

  /** Create (if needed) and activate the audio session: acquire focus, set mode and routing. */
  @Synchronized
  fun start() {
    ensureThread()
    handler?.post {
      val switch = audioSwitch ?: createSwitch().also { audioSwitch = it }
      if (!isActive) {
        switch.activate()
        isActive = true
      }
    }
  }

  /** Deactivate and tear down the audio session: release focus and restore the previous mode. */
  @Synchronized
  fun stop() {
    val h = handler ?: return
    h.removeCallbacksAndMessages(null)
    h.postAtFrontOfQueue {
      audioSwitch?.stop()
      audioSwitch = null
      isActive = false
    }
    thread?.quitSafely()
    handler = null
    thread = null
  }

  /** Route audio to/from the speakerphone, falling back to the next preferred device. */
  @Synchronized
  fun setSpeakerphoneOn(enable: Boolean) {
    preferredDeviceList = preferredDeviceList(speakerFirst = enable)
    ensureThread()
    handler?.post {
      val switch = audioSwitch ?: createSwitch().also { audioSwitch = it }
      switch.setPreferredDeviceList(preferredDeviceList)
      val device = if (enable) {
        switch.availableAudioDevices.firstOrNull { it is AudioDevice.Speakerphone }
      } else {
        switch.availableAudioDevices.firstOrNull {
          it is AudioDevice.BluetoothHeadset || it is AudioDevice.WiredHeadset || it is AudioDevice.Earpiece
        }
      }
      switch.selectDevice(device)
    }
  }

  /** Clear any forced communication device selection (API 31+). */
  fun clearCommunicationDevice() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      audioManager.clearCommunicationDevice()
    }
  }

  private fun createSwitch(): AbstractAudioSwitch {
    val focusListener = AudioManager.OnAudioFocusChangeListener { }
    // API-aware switch selection, matching the LiveKit Android SDK's
    // AudioSwitchHandler: CommDeviceAudioSwitch uses the modern
    // AudioManager.setCommunicationDevice routing on API 31+.
    val switch = when {
      Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
        CommDeviceAudioSwitch(context, loggingEnabled, focusListener, preferredDeviceList)

      Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
        AudioSwitch(context, loggingEnabled, focusListener, preferredDeviceList)

      else ->
        LegacyAudioSwitch(context, loggingEnabled, focusListener, preferredDeviceList)
    }
    applyConfiguration(switch)
    switch.start { _, _ -> }
    return switch
  }

  private fun applyConfiguration(switch: AbstractAudioSwitch) {
    switch.manageAudioFocus = manageAudioFocus
    switch.audioMode = audioMode
    switch.focusMode = focusMode
    switch.audioStreamType = audioStreamType
    switch.audioAttributeUsageType = audioAttributeUsageType
    switch.audioAttributeContentType = audioAttributeContentType
    switch.forceHandleAudioRouting = forceHandleAudioRouting
  }

  private fun ensureThread() {
    if (thread == null) {
      thread = HandlerThread("LKAudioSwitchThread").also { it.start() }
    }
    if (handler == null) {
      handler = Handler(thread!!.looper)
    }
  }

  private fun preferredDeviceList(speakerFirst: Boolean): List<Class<out AudioDevice>> =
    if (speakerFirst) {
      listOf(
        AudioDevice.BluetoothHeadset::class.java,
        AudioDevice.WiredHeadset::class.java,
        AudioDevice.Speakerphone::class.java,
        AudioDevice.Earpiece::class.java,
      )
    } else {
      listOf(
        AudioDevice.BluetoothHeadset::class.java,
        AudioDevice.WiredHeadset::class.java,
        AudioDevice.Earpiece::class.java,
        AudioDevice.Speakerphone::class.java,
      )
    }
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
