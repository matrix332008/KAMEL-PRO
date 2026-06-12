package com.kamelpro.iptv

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.NetworkInterface
import java.util.Collections

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.kamelpro.iptv/mac"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getMac") {
                result.success(getWifiMac())
            }
        }
    }

    private fun getWifiMac(): String {
        try {
            val interfaces = Collections.list(NetworkInterface.getNetworkInterfaces())
            for (nif in interfaces) {
                if (nif.name.equals("wlan0", ignoreCase = true)) {
                    val mac = nif.hardwareAddress ?: continue
                    return mac.joinToString(":") { String.format("%02X", it) }
                }
            }
        } catch (_: Exception) {}
        return "02:00:00:00:00:00"
    }
}
