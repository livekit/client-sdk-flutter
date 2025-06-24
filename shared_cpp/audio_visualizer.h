#ifndef AUDIO_VISUALIZER_H
#define AUDIO_VISUALIZER_H

#include "fft_processor.h"

#include <complex>
#include <iostream>
#include <vector>

class AudioVisualizer {
public:
  static const int bufferSize = FFTProcessor::kDefaultFFTSize / 2;

public:
  AudioVisualizer(float min_db = FFTProcessor::kDefaultMinDecibels,
                  float max_db = FFTProcessor::kDefaultMaxDecibels,
                  double smoothing_time_constant =
                      FFTProcessor::kDefaultSmoothingTimeConstant,
                  int bands_count = 7);

  ~AudioVisualizer();

  bool Process(const int16_t *audioData, unsigned int numSamples,
               float sampleRate, std::vector<float> &output);

  bool Process(const int16_t *audioData, unsigned int numSamples,
               float sampleRate, std::vector<uint8_t> &output);

private:
  float min_frequency_;
  float max_frequency_;
  float min_db_;
  float max_db_;
  int bands_count_;
  double smoothing_time_constant_;
  std::vector<float> bands_;
  std::unique_ptr<FFTProcessor> fft_processor_;
};

#endif // AUDIO_VISUALIZER_H