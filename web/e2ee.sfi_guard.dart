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

const MAX_SIF_COUNT = 100;
const MAX_SIF_DURATION = 2000;

class SifGuard {
  int consecutiveSifCount = 0;

  int? sifSequenceStartedAt;

  int lastSifReceivedAt = 0;

  int userFramesSinceSif = 0;

  void recordSif() {
    consecutiveSifCount += 1;
    sifSequenceStartedAt ??= DateTime.now().millisecondsSinceEpoch;
    lastSifReceivedAt = DateTime.now().millisecondsSinceEpoch;
  }

  void recordUserFrame() {
    if (sifSequenceStartedAt == null) {
      return;
    } else {
      userFramesSinceSif += 1;
    }
    if (
        // reset if we received more user frames than SIFs
        userFramesSinceSif > consecutiveSifCount ||
            // also reset if we got a new user frame and the latest SIF frame hasn't been updated in a while
            DateTime.now().millisecondsSinceEpoch - lastSifReceivedAt >
                MAX_SIF_DURATION) {
      reset();
    }
  }

  bool isSifAllowed() {
    return consecutiveSifCount < MAX_SIF_COUNT &&
        (sifSequenceStartedAt == null ||
            DateTime.now().millisecondsSinceEpoch - sifSequenceStartedAt! <
                MAX_SIF_DURATION);
  }

  void reset() {
    userFramesSinceSif = 0;
    consecutiveSifCount = 0;
    sifSequenceStartedAt = null;
  }
}
