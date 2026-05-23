/*
 * Copyright 2025 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#if os(iOS)
import AVFoundation
import Flutter
import UIKit
import WebRTC

/// Handles iOS audio session interruptions caused by phone calls and other audio-stealing
/// events, and notifies Flutter when the session is interrupted and when it recovers.
///
/// iOS 16+ no longer reliably fires `AVAudioSessionInterruptionTypeEnded` for cellular
/// calls. Three notification sources are combined so that whichever fires first after
/// the call ends will attempt session recovery:
///
/// 1. `AVAudioSession.interruptionNotification` — works for non-call interruptions and
///    some call scenarios on older OS versions.
/// 2. `UIApplication.didBecomeActiveNotification` — covers the common case where the
///    system phone UI pushed the app to the background.
/// 3. `AVAudioSession.routeChangeNotification` — covers Dynamic Island calls where the
///    app stays in the foreground and never backgrounds, so (2) never fires.
///
/// `isInterrupted` is only cleared when `RTCAudioSession.setActive(true)` succeeds.
/// This means every failed attempt (call still active) silently retries on the next
/// notification rather than resetting the flag prematurely.
@available(iOS 13.0, *)
final class AudioInterruptionHandler: NSObject {
    private weak var channel: FlutterMethodChannel?
    private var isInterrupted = false  // always accessed on main thread

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        registerObservers()
    }

    deinit {
        unregisterObservers()
    }

    // MARK: - Observers

    private func registerObservers() {
        let audioSession = AVAudioSession.sharedInstance()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession
        )
    }

    private func unregisterObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Notification handlers

    @objc private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        if type == .began {
            isInterrupted = true
            channel?.invokeMethod("audioInterruptionBegan", arguments: nil)
            return
        }

        guard type == .ended else { return }
        // Honour the system's shouldResume hint when present.
        if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
            guard AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume)
            else { return }
        }
        recoverAudioSession()
    }

    @objc private func handleDidBecomeActive() {
        guard isInterrupted else { return }
        recoverAudioSession()
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard isInterrupted else { return }
        guard notification.userInfo?[AVAudioSessionRouteChangeReasonKey] is UInt else { return }
        recoverAudioSession()
    }

    // MARK: - Recovery

    private func recoverAudioSession() {
        guard isInterrupted else { return }
        // Apple recommends a brief pause before reactivating. Without it,
        // setActive can fail even after the interruption genuinely ended.
        // isInterrupted is NOT cleared here — only on confirmed activation —
        // so if the call is still active the next notification retries.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.isInterrupted else { return }
            let rtcSession = RTCAudioSession.sharedInstance()
            rtcSession.lockForConfiguration()
            var error: NSError?
            let activated = rtcSession.setActive(true, error: &error)
            rtcSession.unlockForConfiguration()
            if activated {
                self.isInterrupted = false
                self.channel?.invokeMethod("audioInterruptionEnded", arguments: nil)
            }
        }
    }
}
#endif
