#ifndef AUDIO_RENDERER_H
#define AUDIO_RENDERER_H

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

// Audio format requested by the Dart caller for a given audio renderer.
struct RendererAudioFormat {
  int bits_per_sample = 16;
  int sample_rate = 48000;
  int channels = 1;
  std::string common_format = "int16";

  // Applies the same defaults as the Android `RendererAudioFormat.fromMap`
  // factory for any missing/invalid value.
  static RendererAudioFormat FromValues(const std::string &common_format,
                                        int sample_rate, int channels);
};

struct AudioConversionResult {
  bool success = false;
  std::vector<uint8_t> data;
  int frame_length = 0;
  int channels = 0;
};

// Resamples interleaved int16 PCM from src_rate to target_rate: linear
// interpolation when upsampling, a box filter (per-sample average) when
// downsampling. Returns the input unchanged when the rates already match.
// Sets out_frames to 0 and returns an empty vector if resampling is not
// possible (invalid frame/channel count, or the target frame count is 0).
std::vector<int16_t> ResampleAudio(const int16_t *src, int src_frames,
                                   int src_rate, int target_rate,
                                   int channels, int &out_frames);

// Converts raw interleaved PCM audio delivered by a WebRTC AudioTrackSink
// into the renderer's target format: resample -> keep the first N channels
// -> encode as int16 or float32 little-endian bytes. `bits_per_sample` must
// be 16, since WebRTC audio sinks always deliver 16-bit signed PCM; any other
// value, or a zero channel/frame count, yields `success = false`.
AudioConversionResult
ConvertAudioData(const void *audio_data, int bits_per_sample, int sample_rate,
                 size_t number_of_channels, size_t number_of_frames,
                 const RendererAudioFormat &target_format);

#endif // AUDIO_RENDERER_H
