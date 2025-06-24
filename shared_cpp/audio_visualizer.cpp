#include "audio_visualizer.h"

#include <chrono>

double CurrentTime() {
  return static_cast<double>(
             std::chrono::duration_cast<std::chrono::milliseconds>(
                 std::chrono::system_clock::now().time_since_epoch())
                 .count()) /
         1000.0;
}

/// Centers the sorted bands by placing higher values in the middle.
std::vector<float> centerBands(const std::vector<float> &sortedBands) {
  std::vector<float> centeredBands(sortedBands.size(), 0.0f);
  size_t leftIndex = sortedBands.size() / 2;
  size_t rightIndex = leftIndex;

  for (size_t index = 0; index < sortedBands.size(); ++index) {
    if (index % 2 == 0) {
      // Place value to the right
      centeredBands[rightIndex] = sortedBands[index];
      rightIndex += 1;
    } else {
      // Place value to the left
      leftIndex -= 1;
      centeredBands[leftIndex] = sortedBands[index];
    }
  }

  return centeredBands;
}

/// Easing function: ease-in-out cubic
float _easeInOutCubic(float t) {
  return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
}

/// Applies an easing function to smooth the transition.
float _smoothTransition(float oldValue, float newValue, float factor) {
  // Calculate the delta change between the old and new value
  float delta = newValue - oldValue;
  // Apply an ease-in-out cubic easing curve
  float easedFactor = _easeInOutCubic(factor);
  // Calculate and return the smoothed value
  return oldValue + delta * easedFactor;
}

AudioVisualizer::AudioVisualizer(float min_frequency, float max_frequency,
                                 float min_db, float max_db, int bands_count)
    : min_frequency_(min_frequency), max_frequency_(max_frequency),
      min_db_(min_db), max_db_(max_db), bands_count_(bands_count),
      bands_(bands_count, 0.0f),
      fft_processor_(std::make_unique<FFTProcessor>(bufferSize)) {}

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
