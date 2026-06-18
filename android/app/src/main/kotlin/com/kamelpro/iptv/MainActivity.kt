package com.kamelpro.iptv

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.Settings
import android.media.AudioManager
import android.os.Build
import java.security.MessageDigest

class MainActivity: FlutterActivity() {
    private val MAC_CHANNEL = "com.kamelpro.iptv/mac"
    private val VOLUME_CHANNEL = "volume_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Channel متاع MAC
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MAC_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getMac") {
                result.success(getStableMac())
            }
        }

        // ✅ Channel جديد متاع الصوت - هذا يحل مشكل Android 6
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_CHANNEL).setMethodCallHandler { call, result ->
            val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
            when (call.method) {
                "setVolume" -> {
                    val up = call.argument<Boolean>("up") ?: true
                    val direction = if (up) AudioManager.ADJUST_RAISE else AudioManager.ADJUST_LOWER
                    audioManager.adjustStreamVolume(
                        AudioManager.STREAM_MUSIC,
                        direction,
                        AudioManager.FLAG_SHOW_UI // يظهر شريط الصوت متاع النظام
                    )
                    result.success(null)
                }
                "toggleMute" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val direction = AudioManager.ADJUST_TOGGLE_MUTE
                        audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, direction, AudioManager.FLAG_SHOW_UI)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getStableMac(): String {
        return try {
            val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID) ?: "unknown"
            val digest = MessageDigest.getInstance("SHA-1").digest(androidId.toByteArray())
            val hex = digest.joinToString("") { "%02X".format(it) }.substring(0, 12)
            hex.chunked(2).joinToString(":")
        } catch (e: Exception) {
            "02:00:00:00"
        }
    }
}
