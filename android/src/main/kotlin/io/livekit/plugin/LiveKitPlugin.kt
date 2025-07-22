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
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import com.cloudwebrtc.webrtc.FlutterWebRTCPlugin
import com.cloudwebrtc.webrtc.audio.LocalAudioTrack
import io.flutter.plugin.common.BinaryMessenger
import org.webrtc.AudioTrack

/** LiveKitPlugin */
class LiveKitPlugin: FlutterPlugin, MethodCallHandler {
  private var processors = mutableMapOf<String, Visualizer>()
  private var flutterWebRTCPlugin = FlutterWebRTCPlugin.sharedSingleton
  private var binaryMessenger: BinaryMessenger? = null
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "livekit_client")
    channel.setMethodCallHandler(this)
    binaryMessenger = flutterPluginBinding.binaryMessenger
  }

  @SuppressLint("SuspiciousIndentation")
  private fun handleStartVisualizer(@NonNull call: MethodCall, @NonNull result: Result) {
    val trackId = call.argument<String>("trackId")
    val visualizerId = call.argument<String>("visualizerId")
    if (trackId == null || visualizerId == null) {
      result.error("INVALID_ARGUMENT", "trackId and visualizerId is required", null)
      return
    }
    var audioTrack: LKAudioTrack? = null
    val barCount = call.argument<Int>("barCount") ?: 7
    val isCentered = call.argument<Boolean>("isCentered") ?: true
    var smoothTransition = call.argument<Boolean>("smoothTransition") ?: true

    val track = flutterWebRTCPlugin.getLocalTrack(trackId)
    if (track != null) {
      audioTrack = LKLocalAudioTrack(track as LocalAudioTrack)
    } else {
      val remoteTrack = flutterWebRTCPlugin.getRemoteTrack(trackId)
        if (remoteTrack != null) {
            audioTrack = LKRemoteAudioTrack(remoteTrack as AudioTrack)
        }
    }

    if(audioTrack == null) {
      result.error("INVALID_ARGUMENT", "track not found", null)
      return
    }

    val visualizer = Visualizer(
      barCount = barCount, isCentered = isCentered, 
      smoothTransition = smoothTransition,
      audioTrack = audioTrack, binaryMessenger = binaryMessenger!!,
      visualizerId = visualizerId)

    processors[visualizerId] = visualizer
    result.success(null)
  }

  private fun handleStopVisualizer(@NonNull call: MethodCall, @NonNull result: Result) {
    val trackId = call.argument<String>("trackId")
    val visualizerId = call.argument<String>("visualizerId")
    if (trackId == null || visualizerId == null) {
      result.error("INVALID_ARGUMENT", "trackId and visualizerId is required", null)
      return
    }
    processors.forEach { (k, visualizer) ->
      if(k == visualizerId) {
        visualizer.stop()
      }
    }
    processors.entries.removeAll { (k, v) -> k == visualizerId }
    result.success(null)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if(call.method == "startVisualizer") {
      handleStartVisualizer(call, result)
      return
    } else if(call.method == "stopVisualizer") {
      handleStopVisualizer(call, result)
      return
    }
    // no-op for now
    result.notImplemented()
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
