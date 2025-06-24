// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "include/livekit_client/live_kit_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <flutter_common.h>
#include <flutter_webrtc.h>
#include <flutter_webrtc/flutter_web_r_t_c_plugin.h>

#include <iomanip>
#include <map>
#include <memory>
#include <sstream>

#include "audio_visualizer.h"

namespace {

class VisualizerSink : public libwebrtc::AudioTrackSink {
public:
  VisualizerSink() {}
  ~VisualizerSink() override {}

public:
  void OnData(const void *audio_data, int bits_per_sample, int sample_rate,
              size_t number_of_channels, size_t number_of_frames) override {

    std::vector<uint8_t> bands;
    if (audio_visualizer_.Process((const int16_t *)audio_data,
                                  (unsigned int)number_of_frames,
                                  float(sample_rate), bands)) {
      std::cout << "Processed audio data into bands: ";
      for (const auto &band : bands) {
        std::cout << static_cast<int>(band) << ", ";
      }
      std::cout << std::endl;
    }
  }

private:
  AudioVisualizer audio_visualizer_;
};

class LiveKitPlugin : public flutter::Plugin {
public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  LiveKitPlugin();

  virtual ~LiveKitPlugin();

private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

private:
  flutter_webrtc_plugin::FlutterWebRTC *webrtc_instance_ = nullptr;
  VisualizerSink audio_sink_; // Example audio sink instance
};

// static
void LiveKitPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "livekit_client",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<LiveKitPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

LiveKitPlugin::LiveKitPlugin() {
  webrtc_instance_ = FlutterWebRTCPluginSharedInstance();
}

LiveKitPlugin::~LiveKitPlugin() {}

void LiveKitPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("startVisualizer") == 0) {
    if (!method_call.arguments()) {
      result->Error("Bad Arguments", "Null arguments received");
      return;
    }
    flutter::EncodableMap params =
        GetValue<flutter::EncodableMap>(*method_call.arguments());
    std::string trackId = findString(params, "trackId");
    std::string visualizerId = findString(params, "visualizerId");
    int barCount = GetValue<int>(params["barCount"]);
    bool isCentered = GetValue<bool>(params["isCentered"]);
    if (trackId.empty() || visualizerId.empty()) {
      result->Error("Invalid Arguments",
                    "trackId and visualizerId are required");
      return;
    }
    libwebrtc::RTCAudioTrack *media_track =
        (libwebrtc::RTCAudioTrack *)webrtc_instance_->MediaTrackForId(trackId);
    if (!media_track) {
      result->Error("Track Not Found", "No media track found for the given ID");
      return;
    }

    media_track->AddSink(&audio_sink_);

    std::cout << "Starting visualizer for trackId: " << trackId
              << ", visualizerId: " << visualizerId
              << ", barCount: " << barCount
              << ", isCentered: " << (isCentered ? "true" : "false")
              << std::endl;

    result->Success(flutter::EncodableValue("Visualizer started"));
  } else if (method_call.method_name().compare("stopVisualizer") == 0) {
    if (!method_call.arguments()) {
      result->Error("Bad Arguments", "Null arguments received");
      return;
    }
    flutter::EncodableMap args =
        GetValue<flutter::EncodableMap>(*method_call.arguments());
    std::string trackId = findString(args, "trackId");
    std::string visualizerId = findString(args, "visualizerId");
    std::cout << "Stopping visualizer for trackId: " << trackId
              << ", visualizerId: " << visualizerId << std::endl;

    libwebrtc::RTCAudioTrack *media_track =
        (libwebrtc::RTCAudioTrack *)webrtc_instance_->MediaTrackForId(trackId);
    if (!media_track) {
      result->Error("Track Not Found", "No media track found for the given ID");
      return;
    }

    media_track->RemoveSink(&audio_sink_);

    result->Success(flutter::EncodableValue("Visualizer stopped"));
  } else {
    result->NotImplemented();
  }
}

} // namespace

void LiveKitPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  LiveKitPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
