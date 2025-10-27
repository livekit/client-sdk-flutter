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
    public let rendererId: String
    public let format: AVAudioFormat // Target format

    private var eventSink: FlutterEventSink?
    private var channel: FlutterEventChannel?

    private var converter: AudioConverter?

    // Weak ref
    private weak var _track: AudioTrack?

    public init(track: AudioTrack,
                binaryMessenger: FlutterBinaryMessenger,
                rendererId: String,
                format: AVAudioFormat)
    {
        _track = track
        self.rendererId = rendererId
        self.format = format

        super.init()
        _track?.add(audioRenderer: self)

        let channelName = "io.livekit.audio.renderer/channel-" + rendererId
        channel = FlutterEventChannel(name: channelName, binaryMessenger: binaryMessenger)
        channel?.setStreamHandler(self)
    }

    func detach() {
        _track?.remove(audioRenderer: self)
    }

    deinit {
        detach()
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

public extension AVAudioPCMBuffer {
    func serialize() -> [String: Any] {
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
            "sampleRate": UInt(format.sampleRate),
            "channels": UInt(format.channelCount),
            "frameLength": UInt(frameLength),
        ]

        // Extract audio data based on the buffer format
        if let floatChannelData {
            // Buffer contains float data
            var channelsData: [[Float]] = []

            for channel in 0 ..< Int(format.channelCount) {
                let channelPointer = floatChannelData[channel]
                let channelArray = Array(UnsafeBufferPointer<Float32>(start: channelPointer, count: Int(frameLength)))
                channelsData.append(channelArray)
            }

            result["data"] = channelsData
            result["commonFormat"] = "float32"
        } else if let int16ChannelData {
            // Buffer contains int16 data
            var channelsData: [[Int16]] = []

            for channel in 0 ..< Int(format.channelCount) {
                let channelPointer = int16ChannelData[channel]
                let channelArray = Array(UnsafeBufferPointer<Int16>(start: channelPointer, count: Int(frameLength)))
                channelsData.append(channelArray)
            }

            result["data"] = channelsData
            result["commonFormat"] = "int16"
        } else if let int32ChannelData {
            // Buffer contains int32 data
            var channelsData: [[Int32]] = []

            for channel in 0 ..< Int(format.channelCount) {
                let channelPointer = int32ChannelData[channel]
                let channelArray = Array(UnsafeBufferPointer<Int32>(start: channelPointer, count: Int(frameLength)))
                channelsData.append(channelArray)
            }

            result["data"] = channelsData
            result["commonFormat"] = "int32"
        } else {
            // Fallback - send minimal info if no recognizable data format
            result["data"] = []
            result["commonFormat"] = "unknown"
        }

        return result
    }
}

extension AudioRenderer: RTCAudioRenderer {
    public func render(pcmBuffer: AVAudioPCMBuffer) {
        guard let eventSink else { return }

        // Create or update converter if needed
        if converter == nil || pcmBuffer.format != converter!.inputFormat || format != converter!.outputFormat {
            converter = AudioConverter(from: pcmBuffer.format, to: format)
        }

        let convertedBuffer = converter!.convert(from: pcmBuffer)

        guard convertedBuffer.frameLength == UInt32(format.sampleRate / 100) else {
            print("Converted buffer frame length does not match target format sample rate: \(convertedBuffer.frameLength) != \(format.sampleRate / 100) skipping this frame...")
            return
        }

        let serializedBuffer = convertedBuffer.serialize()

        // Send the result to Flutter on the main thread
        DispatchQueue.main.async {
            eventSink(serializedBuffer)
        }
    }
}
