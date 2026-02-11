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

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import org.webrtc.AudioTrackSink
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * AudioRenderer for capturing audio data from WebRTC tracks and streaming to Flutter
 * Similar to iOS AudioRenderer implementation
 */
class AudioRenderer(
  private val audioTrack: LKAudioTrack,
  private val binaryMessenger: BinaryMessenger,
  private val rendererId: String,
  private val targetFormat: RendererAudioFormat
) : EventChannel.StreamHandler, AudioTrackSink {

  private var eventChannel: EventChannel? = null
  private var eventSink: EventChannel.EventSink? = null
  private var isAttached = false

  private val handler: Handler by lazy {
    Handler(Looper.getMainLooper())
  }

  init {
    val channelName = "io.livekit.audio.renderer/channel-$rendererId"
    eventChannel = EventChannel(binaryMessenger, channelName)
    eventChannel?.setStreamHandler(this)

    // Attach to the audio track
    audioTrack.addSink(this)
    isAttached = true
  }

  fun detach() {
    if (isAttached) {
      audioTrack.removeSink(this)
      isAttached = false
    }
    eventChannel?.setStreamHandler(null)
    eventSink = null
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  override fun onData(
    audioData: ByteBuffer,
    bitsPerSample: Int,
    sampleRate: Int,
    numberOfChannels: Int,
    numberOfFrames: Int,
    absoluteCaptureTimestampMs: Long
  ) {
    eventSink?.let { sink ->
      try {
        // Convert audio data to the target format
        val convertedData = convertAudioData(
          audioData,
          bitsPerSample,
          sampleRate,
          numberOfChannels,
          numberOfFrames
        )

        // Send to Flutter on the main thread
        handler.post {
          sink.success(convertedData)
        }
      } catch (e: Exception) {
        handler.post {
          sink.error(
            "AUDIO_CONVERSION_ERROR",
            "Failed to convert audio data: ${e.message}",
            null
          )
        }
      }
    }
  }

  /**
   * Converts audio data to raw interleaved bytes.
   *
   * If source and target channel counts match, data is copied directly.
   * If target requests fewer channels, the first channels are kept and interleaved.
   *
   * Sends raw byte arrays instead of boxed sample lists.
   */
  private fun convertAudioData(
    audioData: ByteBuffer,
    bitsPerSample: Int,
    sampleRate: Int,
    numberOfChannels: Int,
    numberOfFrames: Int
  ): Map<String, Any> {
    require(bitsPerSample == 16 || bitsPerSample == 32) {
      "Unsupported bitsPerSample: $bitsPerSample"
    }
    require(numberOfChannels > 0) {
      "Invalid numberOfChannels: $numberOfChannels"
    }

    val outChannels = targetFormat.numberOfChannels.coerceAtMost(numberOfChannels)

    val result = mutableMapOf<String, Any>(
      "sampleRate" to sampleRate,
      "channels" to outChannels,
    )

    val buffer = audioData.duplicate()
    buffer.order(ByteOrder.LITTLE_ENDIAN)
    buffer.rewind()

    when (targetFormat.commonFormat) {
      "int16" -> {
        result["commonFormat"] = "int16"
        result["data"] = extractAsInt16Bytes(buffer, bitsPerSample, numberOfChannels, outChannels, numberOfFrames)
      }
      "float32" -> {
        result["commonFormat"] = "float32"
        result["data"] = extractAsFloat32Bytes(buffer, bitsPerSample, numberOfChannels, outChannels, numberOfFrames)
      }
      else -> {
        result["commonFormat"] = "int16"
        result["data"] = extractAsInt16Bytes(buffer, bitsPerSample, numberOfChannels, outChannels, numberOfFrames)
      }
    }

    return result
  }

  private fun extractAsInt16Bytes(
    buffer: ByteBuffer,
    bitsPerSample: Int,
    srcChannels: Int,
    outChannels: Int,
    numberOfFrames: Int
  ): ByteArray {
    // Fast path for int16 with matching channel count.
    if (bitsPerSample == 16 && srcChannels == outChannels) {
      val totalBytes = numberOfFrames * outChannels * 2
      val out = ByteArray(totalBytes)
      buffer.get(out, 0, totalBytes.coerceAtMost(buffer.remaining()))
      return out
    }

    val out = ByteArray(numberOfFrames * outChannels * 2)
    val outBuf = ByteBuffer.wrap(out).order(ByteOrder.LITTLE_ENDIAN)

    when (bitsPerSample) {
      16 -> {
        for (frame in 0 until numberOfFrames) {
          val srcOffset = frame * srcChannels * 2
          for (ch in 0 until outChannels) {
            val byteIndex = srcOffset + ch * 2
            if (byteIndex + 1 < buffer.capacity()) {
              buffer.position(byteIndex)
              outBuf.putShort((frame * outChannels + ch) * 2, buffer.short)
            }
          }
        }
      }
      32 -> {
        for (frame in 0 until numberOfFrames) {
          val srcOffset = frame * srcChannels * 4
          for (ch in 0 until outChannels) {
            val byteIndex = srcOffset + ch * 4
            if (byteIndex + 3 < buffer.capacity()) {
              buffer.position(byteIndex)
              val sample16 = (buffer.int shr 16).toShort()
              outBuf.putShort((frame * outChannels + ch) * 2, sample16)
            }
          }
        }
      }
    }

    return out
  }

  private fun extractAsFloat32Bytes(
    buffer: ByteBuffer,
    bitsPerSample: Int,
    srcChannels: Int,
    outChannels: Int,
    numberOfFrames: Int
  ): ByteArray {
    // Fast path for float32 with matching channel count.
    if (bitsPerSample == 32 && srcChannels == outChannels) {
      val totalBytes = numberOfFrames * outChannels * 4
      val out = ByteArray(totalBytes)
      buffer.get(out, 0, totalBytes.coerceAtMost(buffer.remaining()))
      return out
    }

    val out = ByteArray(numberOfFrames * outChannels * 4)
    val outBuf = ByteBuffer.wrap(out).order(ByteOrder.LITTLE_ENDIAN)

    when (bitsPerSample) {
      16 -> {
        for (frame in 0 until numberOfFrames) {
          val srcOffset = frame * srcChannels * 2
          for (ch in 0 until outChannels) {
            val byteIndex = srcOffset + ch * 2
            if (byteIndex + 1 < buffer.capacity()) {
              buffer.position(byteIndex)
              val sampleFloat = buffer.short.toFloat() / Short.MAX_VALUE
              outBuf.putFloat((frame * outChannels + ch) * 4, sampleFloat)
            }
          }
        }
      }
      32 -> {
        for (frame in 0 until numberOfFrames) {
          val srcOffset = frame * srcChannels * 4
          for (ch in 0 until outChannels) {
            val byteIndex = srcOffset + ch * 4
            if (byteIndex + 3 < buffer.capacity()) {
              buffer.position(byteIndex)
              outBuf.putFloat((frame * outChannels + ch) * 4, buffer.float)
            }
          }
        }
      }
    }

    return out
  }
}

/**
 * Audio format specification for the renderer
 */
data class RendererAudioFormat(
  val bitsPerSample: Int,
  val sampleRate: Int,
  val numberOfChannels: Int,
  val commonFormat: String = "int16"
) {
  companion object {
    fun fromMap(formatMap: Map<String, Any?>): RendererAudioFormat? {
      val bitsPerSample = formatMap["bitsPerSample"] as? Int ?: 16
      val sampleRate = formatMap["sampleRate"] as? Int ?: 48000
      val numberOfChannels = formatMap["channels"] as? Int ?: 1
      val commonFormat = formatMap["commonFormat"] as? String ?: "int16"

      return RendererAudioFormat(bitsPerSample, sampleRate, numberOfChannels, commonFormat)
    }
  }
}
