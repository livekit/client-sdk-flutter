/*
 * Copyright 2024 LiveKit, Inc.
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

import android.annotation.SuppressLint
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import com.cloudwebrtc.webrtc.FlutterWebRTCPlugin
import com.cloudwebrtc.webrtc.audio.AudioSwitchManager
import com.cloudwebrtc.webrtc.audio.LocalAudioTrack
import io.flutter.plugin.common.BinaryMessenger
import org.webrtc.AudioTrack
import org.webrtc.audio.AudioProcessingComponentOptions
import org.webrtc.audio.AudioProcessingComponentState
import org.webrtc.audio.AudioProcessingImplementation
import org.webrtc.audio.AudioProcessingMode
import org.webrtc.audio.AudioProcessingOptions
import org.webrtc.audio.AudioProcessingOptionsResult
import org.webrtc.audio.AudioProcessingState
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

/** LiveKitPlugin */
class LiveKitPlugin : FlutterPlugin, MethodCallHandler {
  private var audioProcessors = mutableMapOf<String, AudioProcessors>()
  private var flutterWebRTCPlugin = FlutterWebRTCPlugin.sharedSingleton
  private var binaryMessenger: BinaryMessenger? = null
  private var audioSwitchManager: LKAudioSwitchManager? = null
  private var audioDeviceModuleExecutor: ExecutorService? = null
  private val mainHandler = Handler(Looper.getMainLooper())

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // LiveKit owns the platform audio session, so disable flutter_webrtc's own
    // native audio management. Set at registration, before any audio op.
    AudioSwitchManager.setAudioSessionManagementEnabled(false)
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "livekit_client")
    channel.setMethodCallHandler(this)
    binaryMessenger = flutterPluginBinding.binaryMessenger
    audioSwitchManager = LKAudioSwitchManager(flutterPluginBinding.applicationContext)
    audioDeviceModuleExecutor?.shutdown()
    audioDeviceModuleExecutor = Executors.newSingleThreadExecutor()
  }

  @SuppressLint("SuspiciousIndentation")
  private fun handleStartVisualizer(@NonNull call: MethodCall, @NonNull result: Result) {
    val trackId = call.argument<String>("trackId")
    val visualizerId = call.argument<String>("visualizerId")
    if (trackId == null || visualizerId == null) {
      result.error("INVALID_ARGUMENT", "trackId and visualizerId is required", null)
      return
    }

    val barCount = call.argument<Int>("barCount") ?: 7
    val isCentered = call.argument<Boolean>("isCentered") ?: true
    var smoothTransition = call.argument<Boolean>("smoothTransition") ?: true

    val processors = getAudioProcessors(trackId)
    if (processors == null) {
      result.error("INVALID_ARGUMENT", "track not found", null)
      return
    }

    // Check if visualizer already exists
    if (processors.visualizers[visualizerId] != null) {
      result.success(null)
      return
    }

    val visualizer = Visualizer(
      barCount = barCount,
      isCentered = isCentered,
      smoothTransition = smoothTransition,
      audioTrack = processors.track,
      binaryMessenger = binaryMessenger!!,
      visualizerId = visualizerId
    )

    processors.visualizers[visualizerId] = visualizer
    result.success(null)
  }

  private fun handleStopVisualizer(@NonNull call: MethodCall, @NonNull result: Result) {
    val trackId = call.argument<String>("trackId")
    val visualizerId = call.argument<String>("visualizerId")
    if (trackId == null || visualizerId == null) {
      result.error("INVALID_ARGUMENT", "trackId and visualizerId is required", null)
      return
    }

    // Find and remove visualizer from all processors
    for (processors in audioProcessors.values) {
      processors.visualizers[visualizerId]?.let { visualizer ->
        visualizer.stop()
        processors.visualizers.remove(visualizerId)
      }
    }

    result.success(null)
  }

  /**
   * Get or create AudioProcessors for a given trackId
   */
  private fun getAudioProcessors(trackId: String): AudioProcessors? {
    // Return existing if found
    audioProcessors[trackId]?.let { return it }

    // Create new AudioProcessors for this track
    var audioTrack: LKAudioTrack? = null

    val localTrack = flutterWebRTCPlugin.getLocalTrack(trackId)
    if (localTrack != null) {
      audioTrack = LKLocalAudioTrack(localTrack as LocalAudioTrack)
    } else {
      val remoteTrack = flutterWebRTCPlugin.getRemoteTrack(trackId)
      if (remoteTrack != null) {
        audioTrack = LKRemoteAudioTrack(remoteTrack as AudioTrack)
      }
    }

    return audioTrack?.let { track ->
      val processors = AudioProcessors(track)
      audioProcessors[trackId] = processors
      processors
    }
  }

  /**
   * Handle startAudioRenderer method call
   */
  private fun handleStartAudioRenderer(@NonNull call: MethodCall, @NonNull result: Result) {
    val trackId = call.argument<String>("trackId")
    val rendererId = call.argument<String>("rendererId")
    val formatMap = call.argument<Map<String, Any?>>("format")

    if (trackId == null) {
      result.error("INVALID_ARGUMENT", "trackId is required", null)
      return
    }

    if (rendererId == null) {
      result.error("INVALID_ARGUMENT", "rendererId is required", null)
      return
    }

    if (formatMap == null) {
      result.error("INVALID_ARGUMENT", "format is required", null)
      return
    }

    val format = RendererAudioFormat.fromMap(formatMap)
    if (format == null) {
      result.error("INVALID_ARGUMENT", "Failed to parse format", null)
      return
    }

    val processors = getAudioProcessors(trackId)
    if (processors == null) {
      result.error("INVALID_ARGUMENT", "No such track", null)
      return
    }

    // Check if renderer already exists
    if (processors.renderers[rendererId] != null) {
      result.success(true)
      return
    }

    try {
      val renderer = AudioRenderer(
        processors.track,
        binaryMessenger!!,
        rendererId,
        format,
      )

      processors.renderers[rendererId] = renderer
      result.success(true)
    } catch (e: Exception) {
      result.error("RENDERER_ERROR", "Failed to create audio renderer: ${e.message}", null)
    }
  }

  /**
   * Handle stopAudioRenderer method call
   */
  private fun handleStopAudioRenderer(@NonNull call: MethodCall, @NonNull result: Result) {
    val rendererId = call.argument<String>("rendererId")

    if (rendererId == null) {
      result.error("INVALID_ARGUMENT", "rendererId is required", null)
      return
    }

    // Find and remove renderer from all processors
    for (processors in audioProcessors.values) {
      processors.renderers[rendererId]?.let { renderer ->
        renderer.detach()
        processors.renderers.remove(rendererId)
      }
    }

    result.success(true)
  }

  private fun handleSetAudioProcessingOptions(call: MethodCall, result: Result) {
    val trackId = call.argument<String>("trackId")
    if (trackId == null) {
      result.error("INVALID_ARGUMENT", "trackId is required", null)
      return
    }

    val mediaTrack = (flutterWebRTCPlugin.getLocalTrack(trackId) as? LocalAudioTrack)?.track
    if (mediaTrack !is AudioTrack) {
      result.error("INVALID_ARGUMENT", "track is not a local audio track", null)
      return
    }

    val options = audioProcessingOptions(call)
    val processingResult = mediaTrack.setAudioProcessingOptions(options)
    result.success(
      mapOf(
        "result" to processingResult.isSuccess,
        "code" to audioProcessingResultCodeString(processingResult.code),
        "message" to processingResult.message,
      ),
    )
  }

  private fun handleStartLocalRecording(call: MethodCall, result: Result) {
    val audioDeviceModule = flutterWebRTCPlugin.audioDeviceModule
    if (audioDeviceModule == null) {
      result.error("rejectedPlatformUnavailable", "audio device module is unavailable", null)
      return
    }

    val executor = audioDeviceModuleExecutorOrError(result, "rejectedPlatformUnavailable") ?: return
    val options = audioProcessingOptions(call)
    try {
      executor.execute {
        try {
          // prewarmRecording applies Android platform AP and prepares recording
          // without setting the client-start flag. WebRTC exposes this as void,
          // so only thrown failures can be surfaced here.
          audioDeviceModule.prewarmRecording(options)
          mainHandler.post {
            result.success(null)
          }
        } catch (error: Throwable) {
          mainHandler.post {
            result.error("applyFailed", error.message, null)
          }
        }
      }
    } catch (error: RejectedExecutionException) {
      result.error("rejectedPlatformUnavailable", "audio device module executor is unavailable", null)
    }
  }

  private fun handleStopLocalRecording(result: Result) {
    val audioDeviceModule = flutterWebRTCPlugin.audioDeviceModule
    if (audioDeviceModule == null) {
      result.error("stopLocalRecording", "audio device module is unavailable", null)
      return
    }

    val executor = audioDeviceModuleExecutorOrError(result, "stopLocalRecording") ?: return
    try {
      executor.execute {
        try {
          audioDeviceModule.requestStopRecording()
          mainHandler.post {
            result.success(null)
          }
        } catch (error: Throwable) {
          mainHandler.post {
            result.error("stopLocalRecording", error.message, null)
          }
        }
      }
    } catch (error: RejectedExecutionException) {
      result.error("stopLocalRecording", "audio device module executor is unavailable", null)
    }
  }

  private fun audioDeviceModuleExecutorOrError(result: Result, code: String): ExecutorService? {
    val executor = audioDeviceModuleExecutor
    if (executor == null || executor.isShutdown) {
      result.error(code, "audio device module executor is unavailable", null)
      return null
    }
    return executor
  }

  private fun audioProcessingOptions(call: MethodCall): AudioProcessingOptions =
    AudioProcessingOptions(
      AudioProcessingComponentOptions(
        call.argument<Boolean>("echoCancellation") ?: true,
        audioProcessingMode(call.argument<String>("echoCancellationMode")),
      ),
      AudioProcessingComponentOptions(
        call.argument<Boolean>("noiseSuppression") ?: true,
        audioProcessingMode(call.argument<String>("noiseSuppressionMode")),
      ),
      AudioProcessingComponentOptions(
        call.argument<Boolean>("autoGainControl") ?: true,
        audioProcessingMode(call.argument<String>("autoGainControlMode")),
      ),
      AudioProcessingComponentOptions(
        call.argument<Boolean>("highPassFilter") ?: false,
        audioProcessingMode(call.argument<String>("highPassFilterMode")),
      ),
    )

  private fun audioProcessingMode(value: String?): AudioProcessingMode = when (value) {
    "platform" -> AudioProcessingMode.PLATFORM
    "software" -> AudioProcessingMode.SOFTWARE
    else -> AudioProcessingMode.AUTOMATIC
  }

  private fun audioProcessingResultCodeString(code: AudioProcessingOptionsResult.Code): String = when (code) {
    AudioProcessingOptionsResult.Code.APPLIED -> "applied"
    AudioProcessingOptionsResult.Code.STORED -> "stored"
    AudioProcessingOptionsResult.Code.REJECTED_REMOTE_TRACK -> "unknown"
    AudioProcessingOptionsResult.Code.REJECTED_INVALID_COMBINATION -> "rejectedInvalidCombination"
    AudioProcessingOptionsResult.Code.REJECTED_PLATFORM_UNAVAILABLE -> "rejectedPlatformUnavailable"
    AudioProcessingOptionsResult.Code.APPLY_FAILED -> "applyFailed"
  }

  private fun handleGetAudioProcessingState(result: Result) {
    val factory = flutterWebRTCPlugin.getPeerConnectionFactory()
    if (factory == null) {
      result.success(null)
      return
    }
    result.success(audioProcessingStateToMap(factory.audioProcessingState))
  }

  private fun audioProcessingModeString(mode: AudioProcessingMode): String = when (mode) {
    AudioProcessingMode.PLATFORM -> "platform"
    AudioProcessingMode.SOFTWARE -> "software"
    AudioProcessingMode.AUTOMATIC -> "auto"
  }

  private fun audioProcessingImplementationString(implementation: AudioProcessingImplementation): String =
    when (implementation) {
      AudioProcessingImplementation.UNKNOWN -> "unknown"
      AudioProcessingImplementation.DISABLED -> "disabled"
      AudioProcessingImplementation.SOFTWARE -> "software"
      AudioProcessingImplementation.PLATFORM -> "platform"
      AudioProcessingImplementation.SOFTWARE_AND_PLATFORM -> "softwareAndPlatform"
    }

  private fun requestedToMap(requested: AudioProcessingComponentOptions?): Map<String, Any?>? =
    requested?.let {
      mapOf(
        "enabled" to it.isEnabled,
        "mode" to audioProcessingModeString(it.mode),
      )
    }

  private fun componentToMap(state: AudioProcessingComponentState): Map<String, Any?> = mapOf(
    "requested" to requestedToMap(state.requested),
    "isSoftwareResolved" to state.isSoftwareResolved,
    "isSoftwareActive" to state.isSoftwareActive,
    "isPlatformAvailable" to state.isPlatformAvailable,
    "isPlatformResolved" to state.isPlatformResolved,
    "isPlatformActive" to state.isPlatformActive,
    "effective" to audioProcessingImplementationString(state.effective),
  )

  private fun audioProcessingStateToMap(state: AudioProcessingState): Map<String, Any?> = mapOf(
    "hasAudioProcessingModule" to state.hasAudioProcessingModule,
    "echoCancellation" to componentToMap(state.echoCancellation),
    "noiseSuppression" to componentToMap(state.noiseSuppression),
    "autoGainControl" to componentToMap(state.autoGainControl),
    "highPassFilter" to componentToMap(state.highPassFilter),
  )

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "startVisualizer" -> {
        handleStartVisualizer(call, result)
      }

      "stopVisualizer" -> {
        handleStopVisualizer(call, result)
      }

      "startAudioRenderer" -> {
        handleStartAudioRenderer(call, result)
      }

      "stopAudioRenderer" -> {
        handleStopAudioRenderer(call, result)
      }

      "setAudioProcessingOptions" -> {
        handleSetAudioProcessingOptions(call, result)
      }

      "startLocalRecording" -> {
        handleStartLocalRecording(call, result)
      }

      "stopLocalRecording" -> {
        handleStopLocalRecording(result)
      }

      "getAudioProcessingState" -> {
        handleGetAudioProcessingState(result)
      }

      "configureAndroidAudioSession" -> {
        @Suppress("UNCHECKED_CAST")
        val configuration = call.arguments as? Map<String, Any?> ?: emptyMap()
        audioSwitchManager?.configure(configuration)
        audioSwitchManager?.start()
        result.success(null)
      }

      "stopAndroidAudioSession" -> {
        audioSwitchManager?.stop()
        result.success(null)
      }

      "setAndroidSpeakerphoneOn" -> {
        val enable = call.argument<Boolean>("enable") ?: false
        val force = call.argument<Boolean>("force") ?: false
        audioSwitchManager?.setSpeakerphoneOn(enable, force)
        result.success(null)
      }

      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)

    audioSwitchManager?.dispose()
    audioSwitchManager = null

    audioDeviceModuleExecutor?.shutdown()
    audioDeviceModuleExecutor = null

    // Cleanup all processors
    audioProcessors.values.forEach { it.cleanup() }
    audioProcessors.clear()
  }
}
