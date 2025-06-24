#ifndef AUDIO_VISUALIZER_H
#define AUDIO_VISUALIZER_H

#include "fft_processor.h"

#include <complex>
#include <iostream>
#include <vector>

class AudioVisualizer {
public:
  AudioVisualizer(double smoothing_time_constant =
                      FFTProcessor::kDefaultSmoothingTimeConstant,
                  int bands_count = 7);

  ~AudioVisualizer();

  bool Process(const int16_t *audioData, unsigned int numSamples,
               float sampleRate, std::vector<float> &output);

  bool Process(const int16_t *audioData, unsigned int numSamples,
               float sampleRate, std::vector<uint8_t> &output);

private:
  int bands_count_;
  double smoothing_time_constant_;
  std::vector<float> bands_;
  std::unique_ptr<FFTProcessor> fft_processor_;
};

#endif // AUDIO_VISUALIZER_H