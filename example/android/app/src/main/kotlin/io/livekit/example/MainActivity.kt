package io.livekit.example

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "livekit_incall"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableInCall" -> {
                    setInCallScreenFlags()
                    result.success(null)
                }
                "disableInCall" -> {
                    clearInCallScreenFlags()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setInCallScreenFlags() {
        val window = window

        // Keep screen on during call
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Show over lock screen (modern way)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setTurnScreenOn(true)
            setShowWhenLocked(true)
        } else {
            window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
            window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
            window.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
        }
    }

    private fun clearInCallScreenFlags() {
        val window = window

        // Remove keep screen on
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Reset lock screen behavior
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setTurnScreenOn(false)
            setShowWhenLocked(false)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
            window.clearFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
            window.clearFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
        }
    }
}