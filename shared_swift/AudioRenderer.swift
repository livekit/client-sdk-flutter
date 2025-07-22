/*
 * Copyright 2024 LiveKit
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

import AVFoundation
import WebRTC

#if os(macOS)
    import Cocoa
    import FlutterMacOS
#else
    import Flutter
    import UIKit
#endif

public class AudioRenderer: NSObject {
    private var eventSink: FlutterEventSink?
    private var channel: FlutterEventChannel?

    private weak var _track: AudioTrack?

    public init(track: AudioTrack?,
                binaryMessenger: FlutterBinaryMessenger,
                rendererId: String)
    {
        _track = track
        super.init()
        _track?.add(audioRenderer: self)

        let channelName = "io.livekit.audio.renderer/eventchannel-" + rendererId
        channel = FlutterEventChannel(name: channelName, binaryMessenger: binaryMessenger)
        channel?.setStreamHandler(self)
    }

    deinit {
        _track?.remove(audioRenderer: self)
    }
}

extension AudioRenderer: FlutterStreamHandler {
    public func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments _: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

extension AudioRenderer: RTCAudioRenderer {
    public func render(pcmBuffer _: AVAudioPCMBuffer) {
        eventSink?("audio_renderer_event")
    }
}
