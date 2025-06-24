#include "audio_visualizer.h"

#include <chrono>

static const int bufferSize = FFTProcessor::kDefaultFFTSize / 2;

double CurrentTime() {
  return static_cast<double>(
             std::chrono::duration_cast<std::chrono::milliseconds>(
                 std::chrono::system_clock::now().time_since_epoch())
                 .count()) /
         1000.0;
}

AudioVisualizer::AudioVisualizer(double smoothing_time_constant,
                                 int bands_count)
    : bands_count_(bands_count),
      smoothing_time_constant_(smoothing_time_constant),
      bands_(bands_count, 0.0f),
      fft_processor_(std::make_unique<FFTProcessor>(bufferSize,
                                                    smoothing_time_constant_)) {
}

AudioVisualizer::~AudioVisualizer() {}

bool AudioVisualizer::Process(const int16_t *audioData, unsigned int numSamples,
                              float sampleRate, std::vector<float> &output) {

  fft_processor_->WriteInput(audioData, numSamples);
  std::vector<float> bands(bands_count_, 0.0f);
  fft_processor_->GetFloatFrequencyData(bands, CurrentTime());
  output = bands;
  return true;
}

bool AudioVisualizer::Process(const int16_t *audioData, unsigned int numSamples,
                              float sampleRate, std::vector<uint8_t> &output) {

  fft_processor_->WriteInput(audioData, numSamples);
  std::vector<uint8_t> bands(bands_count_, 0);
  fft_processor_->GetByteFrequencyData(bands, CurrentTime());
  output = bands;
  return true;
}
