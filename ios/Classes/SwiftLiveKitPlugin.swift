import Flutter
import UIKit
import WebRTC

public class SwiftLiveKitPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "livekit_client", binaryMessenger: registrar.messenger())
        let instance = SwiftLiveKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // https://developer.apple.com/documentation/avfaudio/avaudiosession/category
    let categoryMap: [String: AVAudioSession.Category] = [
        "ambient": .ambient,
        "multiRoute": .multiRoute,
        "playAndRecord": .playAndRecord,
        "playback": .playback,
        "record": .record,
        "soloAmbient": .soloAmbient,
    ]

    // https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions
    let categoryOptionsMap: [String: AVAudioSession.CategoryOptions] = [
        "mixWithOthers": .mixWithOthers,
        "duckOthers": .duckOthers,
        "interruptSpokenAudioAndMixWithOthers": .interruptSpokenAudioAndMixWithOthers,
        "allowBluetooth": .allowBluetooth,
        "allowBluetoothA2DP": .allowBluetoothA2DP,
        "allowAirPlay": .allowAirPlay,
        "defaultToSpeaker": .defaultToSpeaker,
//        @available(iOS 14.5, *)
//        "overrideMutedMicrophoneInterruption": .overrideMutedMicrophoneInterruption,
    ]

    // https://developer.apple.com/documentation/avfaudio/avaudiosession/mode
    let modeMap: [String: AVAudioSession.Mode] = [
        "default": .default,
        "gameChat": .gameChat,
        "measurement": .measurement,
        "moviePlayback": .moviePlayback,
        "spokenAudio": .spokenAudio,
        "videoChat": .videoChat,
        "videoRecording": .videoRecording,
        "voiceChat": .voiceChat,
        "voicePrompt": .voicePrompt,
    ]

    private func categoryOptions(fromFlutter options: [String]) -> AVAudioSession.CategoryOptions {
        var result: AVAudioSession.CategoryOptions = []
        for option in categoryOptionsMap {
            if (options.contains(option.key)) {
                result.insert(option.value)
            }
        }
        return result
    }

    public func handleConfigureNativeAudio(args: [String: Any?], result: @escaping FlutterResult) {

        let configuration = RTCAudioSessionConfiguration.webRTC()

        // Category
        if let string = args["appleAudioCategory"] as? String,
           let category = categoryMap[string] {
            configuration.category = category.rawValue
            print("[LiveKit] Configuring category: ", configuration.category)
        }

        // CategoryOptions
        if let strings = args["appleAudioCategoryOptions"] as? [String] {
            configuration.categoryOptions = categoryOptions(fromFlutter: strings)
            print("[LiveKit] Configuring categoryOptions: ", strings)
        }

        // Mode
        if let string = args["appleAudioMode"] as? String,
           let mode = modeMap[string] {
            configuration.mode = mode.rawValue
            print("[LiveKit] Configuring mode: ", configuration.mode)
        }

        let session = RTCAudioSession.sharedInstance()
        session.lockForConfiguration()
        defer {
            session.unlockForConfiguration()
        }

        do {
            try session.setConfiguration(configuration, active: true)
            print("[LiveKit] Configure success")
            result(true)
        } catch let error {
            print("[LiveKit] Configure audio error: ", error)
            result(FlutterError(code: "configure", message: error.localizedDescription, details: nil))
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        guard let args = call.arguments as? [String: Any?] else {
            print("[LiveKit] arguments must be a dictionary")
            result(FlutterMethodNotImplemented)
            return
        }

        switch call.method {
        case "configureNativeAudio":
            handleConfigureNativeAudio(args: args, result: result)
        default:
            print("[LiveKit] method not found: ", call.method)
            result(FlutterMethodNotImplemented)
        }
    }
}
