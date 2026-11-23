#!/bin/bash
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

# Runs `dart pub publish --dry-run` and fails on any issue except one.
#
# The exact flutter_webrtc pin is intentional (native WebRTC-SDK pods must
# match) but always gives a pub validation warning, and pub treats any
# warning as fatal without --force. The publish uses --force because of
# that, so this check makes sure that the pin warning is the only issue.
# CI runs it on every PR, so the release PR shows a failure before the
# merge puts the new version on main. release.yaml runs it again before
# the tag.

set +e
output=$(dart pub publish --dry-run 2>&1)
status=$?
set -e
echo "$output"
if [ "$status" -eq 0 ]; then
  exit 0
fi
unexpected=$(echo "$output" | grep '^\* ' | grep -v 'dependency on "flutter_webrtc" should allow more than one version' || true)
if echo "$output" | grep -q '^Package has 1 warning\.$' && [ -z "$unexpected" ]; then
  echo "Only the expected flutter_webrtc pin warning was found, continuing."
  exit 0
fi
echo "Validation found issues other than the expected flutter_webrtc pin warning, refusing to publish."
exit 1
