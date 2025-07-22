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
    public func render(pcmBuffer: AVAudioPCMBuffer) {
        guard let eventSink = eventSink else { return }

        // Extract audio format information
        let sampleRate = pcmBuffer.format.sampleRate
        let channelCount = pcmBuffer.format.channelCount
        let frameLength = pcmBuffer.frameLength

        // The format of the data:
        // {
        //   "sampleRate": 48000.0,
        //   "channelCount": 2,
        //   "frameLength": 480,
        //   "format": "float32", // or "int16", "int32", "unknown"
        //   "data": [
        //     [/* channel 0 audio samples */],
        //     [/* channel 1 audio samples */]
        //   ]
        // }

        // Create the result dictionary to send to Flutter
        var result: [String: Any] = [
            "sampleRate": sampleRate,
            "channelCount": channelCount,
            "frameLength": frameLength,
        ]

        // Extract audio data based on the buffer format
        if let floatChannelData = pcmBuffer.floatChannelData {
            // Buffer contains float data
            var channelsData: [[Float]] = []

            for channel in 0 ..< Int(channelCount) {
                let channelPointer = floatChannelData[channel]
                let channelArray = Array(UnsafeBufferPointer(start: channelPointer, count: Int(frameLength)))
                channelsData.append(channelArray)
            }

            result["data"] = channelsData
            result["format"] = "float32"
        } else if let int16ChannelData = pcmBuffer.int16ChannelData {
            // Buffer contains int16 data
            var channelsData: [[Int16]] = []

            for channel in 0 ..< Int(channelCount) {
                let channelPointer = int16ChannelData[channel]
                let channelArray = Array(UnsafeBufferPointer(start: channelPointer, count: Int(frameLength)))
                channelsData.append(channelArray)
            }

            result["data"] = channelsData
            result["format"] = "int16"
        } else if let int32ChannelData = pcmBuffer.int32ChannelData {
            // Buffer contains int32 data
            var channelsData: [[Int32]] = []

            for channel in 0 ..< Int(channelCount) {
                let channelPointer = int32ChannelData[channel]
                let channelArray = Array(UnsafeBufferPointer(start: channelPointer, count: Int(frameLength)))
                channelsData.append(channelArray)
            }

            result["data"] = channelsData
            result["format"] = "int32"
        } else {
            // Fallback - send minimal info if no recognizable data format
            result["data"] = []
            result["format"] = "unknown"
        }

        // Send the result to Flutter on the main thread
        DispatchQueue.main.async {
            eventSink(result)
        }
    }
}
