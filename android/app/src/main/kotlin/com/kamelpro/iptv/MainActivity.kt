package com.kamelpro.iptv

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.Settings
import java.security.MessageDigest

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.kamelpro.iptv/mac"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getMac") {
                result.success(getStableMac())
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
