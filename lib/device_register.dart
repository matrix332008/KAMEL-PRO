import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';

class DeviceRegister {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://jzusqopbxyltavjrxmuc.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp6dXNxb3BieHlsdGF2anJ4bXVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1NTMwMjAsImV4cCI6MjA2ODEyOTAyMH0.nW-0RJSdQg_GSHTlOJTP-9w-PRQfH5hgxq-hF_gQpGU',
    );
  }

  static Future<String> getMac() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        String id = androidInfo.id + androidInfo.model;
        return sha1.convert(utf8.encode(id)).toString().substring(0, 12).toUpperCase();
      }
      return 'UNKNOWN';
    } catch (e) {
      return 'ERROR';
    }
  }

  static String generateKey() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  static Future<void> register() async {
    try {
      final mac = await getMac();
      final key = generateKey();
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('device_mac', mac);
      await prefs.setString('device_key', key);
      
      await Supabase.instance.client.from('devices').upsert({
        'mac_address': mac,
        'activation_key': key,
        'last_seen': DateTime.now().toIso8601String(),
      }, onConflict: 'mac_address');
      
      print('✅ Registered: $mac - $key');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}
