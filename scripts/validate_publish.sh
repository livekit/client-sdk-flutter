#!/usr/bin/env bash
# Copyright 2026 LiveKit, Inc.
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

# Checks that the package can publish. The exact flutter_webrtc pin is
# intentional (the native WebRTC-SDK pods must match) and always gives one
# pub validation warning, and the publish runs with --force because of it.
# --force lets every warning through, so this dry run is what keeps a new
# one out of a release: it passes only when the pin warning is the single
# validation issue.
set -uo pipefail

output=$(dart pub publish --dry-run 2>&1)
status=$?
echo "$output"
if [ "$status" -eq 0 ]; then
  exit 0
fi

unexpected=$(echo "$output" | grep '^\* ' | grep -v 'dependency on "flutter_webrtc" should allow more than one version' || true)
if echo "$output" | grep -q '^Package has 1 warning\.$' && [ -z "$unexpected" ]; then
  echo "Only the expected flutter_webrtc pin warning was found."
  exit 0
fi

echo "::error::Validation found issues other than the expected flutter_webrtc pin warning."
exit 1
