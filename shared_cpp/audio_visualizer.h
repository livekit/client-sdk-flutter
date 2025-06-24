#ifndef AUDIO_VISUALIZER_H
#define AUDIO_VISUALIZER_H

#include "fft_processor.h"

#include <complex>
#include <iostream>
#include <vector>

class AudioVisualizer {
public:
  static const int bufferSize = 512;

public:
  AudioVisualizer(float min_frequency = 10.0f, float max_frequency = 8000.0f,
                  float min_db = -100.0f, float max_db = -10.0f,
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
  std::vector<float> bands_;
  std::unique_ptr<FFTProcessor> fft_processor_;
};

#endif // AUDIO_VISUALIZER_H