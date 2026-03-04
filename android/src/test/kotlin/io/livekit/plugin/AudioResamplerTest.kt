package io.livekit.plugin

import kotlin.math.PI
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AudioResamplerTest {

  // --- Passthrough ---

  @Test
  fun `same rate returns identical samples`() {
    val src = shortArrayOf(100, 200, 300, 400, 500)
    val result = AudioResampler.resample(src, 5, 48000, 48000, 1)
    assertEquals(5, result.frameCount)
    assertTrue(src.contentEquals(result.samples))
  }

  // --- Upsample ---

  @Test
  fun `upsample 8kHz to 48kHz produces 6x frames`() {
    val srcFrames = 80
    val src = ShortArray(srcFrames) { (it * 100).toShort() }
    val result = AudioResampler.resample(src, srcFrames, 8000, 48000, 1)
    assertEquals(480, result.frameCount)
    assertEquals(480, result.samples.size)
  }

  @Test
  fun `upsample preserves first and last sample`() {
    val src = shortArrayOf(0, 1000, 2000, 3000)
    val result = AudioResampler.resample(src, 4, 8000, 16000, 1)
    assertEquals(0, result.samples[0].toInt())
  }

  @Test
  fun `upsample with stereo preserves channel count`() {
    // 4 frames, 2 channels: [L0, R0, L1, R1, L2, R2, L3, R3]
    val src = shortArrayOf(100, -100, 200, -200, 300, -300, 400, -400)
    val result = AudioResampler.resample(src, 4, 8000, 16000, 2)
    assertEquals(8, result.frameCount)
    assertEquals(16, result.samples.size) // 8 frames * 2 channels
  }

  // --- Downsample ---

  @Test
  fun `downsample 48kHz to 8kHz produces one-sixth frames`() {
    val srcFrames = 480
    val src = ShortArray(srcFrames) { 1000 }
    val result = AudioResampler.resample(src, srcFrames, 48000, 8000, 1)
    assertEquals(80, result.frameCount)
    assertEquals(80, result.samples.size)
    for (s in result.samples) {
      assertEquals(1000, s.toInt())
    }
  }

  @Test
  fun `downsample averages samples correctly`() {
    // 6 samples at 48kHz → 1 sample at 8kHz, should average the 6 values
    val src = shortArrayOf(100, 200, 300, 400, 500, 600)
    val result = AudioResampler.resample(src, 6, 48000, 8000, 1)
    assertEquals(1, result.frameCount)
    // Average of 100..600 = 350
    assertEquals(350, result.samples[0].toInt())
  }

  // --- Sine wave preservation (signal below Nyquist survives) ---

  @Test
  fun `440Hz sine survives downsample from 48kHz to 16kHz`() {
    val srcRate = 48000
    val targetRate = 16000
    val freq = 440.0
    val durationSec = 0.1
    val srcFrames = (srcRate * durationSec).toInt()

    val src = ShortArray(srcFrames) { i ->
      (sin(2.0 * PI * freq * i / srcRate) * 20000).roundToInt().toShort()
    }

    val result = AudioResampler.resample(src, srcFrames, srcRate, targetRate, 1)
    val expectedFrames = (srcFrames.toLong() * targetRate / srcRate).toInt()
    assertEquals(expectedFrames, result.frameCount)

    // Verify the resampled signal still contains 440Hz by checking
    // zero-crossings to estimate frequency
    val zeroCrossings = countZeroCrossings(result.samples, result.frameCount)
    // Each full cycle has 2 zero crossings
    val estimatedFreq = (zeroCrossings / 2.0) / durationSec
    // Allow 10% tolerance
    assertTrue(
      estimatedFreq > freq * 0.9 && estimatedFreq < freq * 1.1,
      "Expected ~440Hz, estimated ${estimatedFreq}Hz (zeroCrossings=$zeroCrossings)"
    )
  }

  // --- Aliasing rejection (signal above Nyquist is attenuated) ---

  @Test
  fun `5kHz sine is attenuated when downsampled to 8kHz`() {
    val srcRate = 48000
    val targetRate = 8000 // Nyquist = 4kHz
    val freq = 5000.0 // Above Nyquist
    val durationSec = 0.05
    val srcFrames = (srcRate * durationSec).toInt()

    val src = ShortArray(srcFrames) { i ->
      (sin(2.0 * PI * freq * i / srcRate) * 20000).roundToInt().toShort()
    }

    val result = AudioResampler.resample(src, srcFrames, srcRate, targetRate, 1)

    // With box filter, the 5kHz signal should be significantly attenuated.
    val inputRms = rms(src, srcFrames)
    val outputRms = rms(result.samples, result.frameCount)

    // Output RMS should be at most 50% of input RMS.
    assertTrue(
      outputRms < inputRms * 0.5,
      "5kHz signal should be attenuated: inputRms=$inputRms, outputRms=$outputRms, " +
        "ratio=${outputRms / inputRms}"
    )
  }

  @Test
  fun `1kHz sine is preserved when downsampled to 8kHz`() {
    val srcRate = 48000
    val targetRate = 8000 // Nyquist = 4kHz
    val freq = 1000.0 // Well below Nyquist
    val durationSec = 0.05
    val srcFrames = (srcRate * durationSec).toInt()

    val src = ShortArray(srcFrames) { i ->
      (sin(2.0 * PI * freq * i / srcRate) * 20000).roundToInt().toShort()
    }

    val result = AudioResampler.resample(src, srcFrames, srcRate, targetRate, 1)

    // 1kHz is well below Nyquist, RMS should remain roughly similar (within 30%)
    val inputRms = rms(src, srcFrames)
    val outputRms = rms(result.samples, result.frameCount)

    assertTrue(
      outputRms > inputRms * 0.7,
      "1kHz signal should be preserved: inputRms=$inputRms, outputRms=$outputRms, " +
        "ratio=${outputRms / inputRms}"
    )
  }

  // --- Edge cases ---

  @Test
  fun `zero frames returns empty`() {
    val result = AudioResampler.resample(ShortArray(0), 0, 48000, 16000, 1)
    assertEquals(0, result.frameCount)
  }

  @Test
  fun `single frame upsample`() {
    val src = shortArrayOf(1000)
    val result = AudioResampler.resample(src, 1, 8000, 48000, 1)
    assertEquals(6, result.frameCount)
  }

  // --- Helpers ---

  private fun countZeroCrossings(samples: ShortArray, count: Int): Int {
    var crossings = 0
    for (i in 1 until count) {
      if ((samples[i - 1] >= 0 && samples[i] < 0) ||
        (samples[i - 1] < 0 && samples[i] >= 0)
      ) {
        crossings++
      }
    }
    return crossings
  }

  private fun rms(samples: ShortArray, count: Int): Double {
    if (count == 0) return 0.0
    var sumSq = 0.0
    for (i in 0 until count) {
      sumSq += samples[i].toDouble() * samples[i].toDouble()
    }
    return kotlin.math.sqrt(sumSq / count)
  }
}
