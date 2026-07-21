#include "audio_renderer.h"

#include <algorithm>
#include <cstring>

namespace {

std::vector<int16_t> UpsampleAudio(const int16_t *src, int src_frames,
                                   int out_frames, int channels) {
  std::vector<int16_t> out(static_cast<size_t>(out_frames) * channels);

  // Edge case: a single source frame — just repeat it.
  if (src_frames <= 1) {
    for (int f = 0; f < out_frames; ++f) {
      for (int ch = 0; ch < channels; ++ch) {
        out[f * channels + ch] = src[ch];
      }
    }
    return out;
  }

  double ratio =
      static_cast<double>(src_frames) / static_cast<double>(out_frames);

  for (int f = 0; f < out_frames; ++f) {
    double src_pos = f * ratio;
    int idx = std::min(static_cast<int>(src_pos), src_frames - 2);
    float frac = static_cast<float>(src_pos - idx);

    for (int ch = 0; ch < channels; ++ch) {
      int16_t s0 = src[idx * channels + ch];
      int16_t s1 = src[(idx + 1) * channels + ch];
      int sample = static_cast<int>(s0 + frac * (s1 - s0));
      sample = std::clamp(sample, static_cast<int>(INT16_MIN),
                          static_cast<int>(INT16_MAX));
      out[f * channels + ch] = static_cast<int16_t>(sample);
    }
  }

  return out;
}

std::vector<int16_t> DownsampleAudio(const int16_t *src, int src_frames,
                                     int out_frames, int src_rate,
                                     int target_rate, int channels) {
  std::vector<int16_t> out(static_cast<size_t>(out_frames) * channels);
  double ratio =
      static_cast<double>(src_rate) / static_cast<double>(target_rate);

  for (int f = 0; f < out_frames; ++f) {
    int src_start = static_cast<int>(f * ratio);
    int src_end = std::min(static_cast<int>((f + 1) * ratio), src_frames);

    for (int ch = 0; ch < channels; ++ch) {
      int64_t sum = 0;
      for (int i = src_start; i < src_end; ++i) {
        sum += src[i * channels + ch];
      }
      int count = src_end - src_start;
      out[f * channels + ch] =
          count > 0 ? static_cast<int16_t>(std::clamp<int64_t>(
                          sum / count, INT16_MIN, INT16_MAX))
                    : 0;
    }
  }

  return out;
}

} // namespace

RendererAudioFormat RendererAudioFormat::FromValues(
    const std::string &common_format, int sample_rate, int channels) {
  RendererAudioFormat format;
  format.common_format = common_format.empty() ? "int16" : common_format;
  format.sample_rate = sample_rate > 0 ? sample_rate : 48000;
  format.channels = channels > 0 ? channels : 1;
  return format;
}

std::vector<int16_t> ResampleAudio(const int16_t *src, int src_frames,
                                   int src_rate, int target_rate,
                                   int channels, int &out_frames) {
  if (src_rate == target_rate || src_frames <= 0 || channels <= 0) {
    out_frames = src_frames;
    return std::vector<int16_t>(
        src, src + static_cast<size_t>(std::max(src_frames, 0)) * channels);
  }

  out_frames = static_cast<int>((static_cast<int64_t>(src_frames) *
                                 target_rate) /
                                src_rate);
  if (out_frames <= 0) {
    out_frames = 0;
    return {};
  }

  if (target_rate > src_rate) {
    return UpsampleAudio(src, src_frames, out_frames, channels);
  }
  return DownsampleAudio(src, src_frames, out_frames, src_rate, target_rate,
                         channels);
}

AudioConversionResult
ConvertAudioData(const void *audio_data, int bits_per_sample, int sample_rate,
                 size_t number_of_channels, size_t number_of_frames,
                 const RendererAudioFormat &target_format) {
  AudioConversionResult result;

  // WebRTC AudioTrackSink always delivers 16-bit signed int16 PCM.
  if (bits_per_sample != 16 || number_of_channels == 0 ||
      number_of_frames == 0) {
    return result;
  }

  int channels = static_cast<int>(number_of_channels);
  int src_frames = static_cast<int>(number_of_frames);
  const int16_t *src = reinterpret_cast<const int16_t *>(audio_data);

  int out_frames = 0;
  std::vector<int16_t> resampled = ResampleAudio(
      src, src_frames, sample_rate, target_format.sample_rate, channels,
      out_frames);
  if (out_frames <= 0) {
    return result;
  }

  int requested_channels = std::max(target_format.channels, 1);
  int out_channels = std::min(requested_channels, channels);

  result.frame_length = out_frames;
  result.channels = out_channels;

  if (target_format.common_format == "float32") {
    result.data.resize(static_cast<size_t>(out_frames) * out_channels * 4);
    for (int f = 0; f < out_frames; ++f) {
      for (int ch = 0; ch < out_channels; ++ch) {
        float sample = resampled[f * channels + ch] / 32767.0f;
        size_t offset = (static_cast<size_t>(f) * out_channels + ch) * 4;
        // memcpy relies on the host being little-endian, true for the
        // x86/x64/ARM desktop targets this plugin builds for.
        std::memcpy(&result.data[offset], &sample, sizeof(float));
      }
    }
  } else {
    result.data.resize(static_cast<size_t>(out_frames) * out_channels * 2);
    for (int f = 0; f < out_frames; ++f) {
      for (int ch = 0; ch < out_channels; ++ch) {
        int16_t sample = resampled[f * channels + ch];
        size_t offset = (static_cast<size_t>(f) * out_channels + ch) * 2;
        result.data[offset] = static_cast<uint8_t>(sample & 0xFF);
        result.data[offset + 1] = static_cast<uint8_t>((sample >> 8) & 0xFF);
      }
    }
  }

  result.success = true;
  return result;
}
