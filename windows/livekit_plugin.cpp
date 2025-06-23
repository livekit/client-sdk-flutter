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

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <flutter_webrtc/flutter_web_r_t_c_plugin.h>

#include <flutter_webrtc.h>

#include <map>
#include <memory>
#include <sstream>

namespace {

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
  FlutterWebRTC *webrtc_instance_ = nullptr;
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
  webrtc_instance_ = FlutterWebRTC::shared_instance();
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
    const EncodableMap params =
        GetValue<EncodableMap>(*method_call.arguments());
    const std::string trackId = findString(params, "trackId");
    const std::string visualizerId = findString(params, "visualizerId");
    const int barCount = GetValue<int>(params["barCount"]);
    const bool isCentered = GetValue<bool>(params["isCentered"]);

    std::cout << "Starting visualizer for trackId: " << trackId
              << ", visualizerId: " << visualizerId
              << ", barCount: " << barCount
              << ", isCentered: " << (isCentered ? "true" : "false") << std::endl;

    result->Success(flutter::EncodableValue(version_stream.str()));
  } else if (method_call.method_name().compare("stopVisualizer") == 0) {
    if (!method_call.arguments()) {
      result->Error("Bad Arguments", "Null arguments received");
      return;
    }
    const EncodableMap args =
        GetValue<EncodableMap>(*method_call.arguments());
    const std::string trackId = findString(args, "trackId");
    const std::string visualizerId = findString(args, "visualizerId");
    std::cout << "Stopping visualizer for trackId: " << trackId
              << ", visualizerId: " << visualizerId << std::endl;
    result->Success(flutter::EncodableValue(version_stream.str()));
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
