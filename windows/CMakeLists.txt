# Copyright 2024 LiveKit, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "livekit_client")
project(${PROJECT_NAME} LANGUAGES CXX C)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "livekit_client_plugin")

add_definitions(-D_USE_MATH_DEFINES)
add_definitions(-DRTC_DESKTOP_DEVICE)

add_library(${PLUGIN_NAME} SHARED
  "livekit_plugin.cpp"
  "task_runner_windows.cpp"
  "../shared_cpp/fft_processor.cpp"
  "../shared_cpp/audio_visualizer.cpp"
  "../shared_cpp/pffft.c"
)

include_directories(
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/../shared_cpp"
)

target_compile_options(${PLUGIN_NAME} PRIVATE /wd4456)
target_compile_options(${PLUGIN_NAME} PRIVATE /wd4244)
target_compile_options(${PLUGIN_NAME} PRIVATE /wd4305)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin flutter_webrtc_plugin)

# List of absolute paths to libraries that should be bundled with the plugin
set(livekit_client_bundled_libraries
  ""
  PARENT_SCOPE
)
