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
    final prefs = await SharedPreferences.getInstance();
    
    // 1. إذا محفوظ من قبل، رجعو طول
    String? savedMac = prefs.getString('device_mac');
    if (savedMac != null) return savedMac;

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // نستعمل id فقط (ثابت مع نفس keystore)
        String id = androidInfo.id;
        String hash = sha1.convert(utf8.encode(id)).toString().substring(0, 12).toUpperCase();
        
        // نحولوه لشكل MAC بالـ : باش يتماشى مع Supabase متاعك
        String mac = hash.replaceAllMapped(RegExp(r'.{2}'), (m) => '${m.group(0)}:');
        mac = mac.substring(0, 17); // 1F:D5:9C:02:4D:79
        
        await prefs.setString('device_mac', mac);
        return mac;
      }
      return '00:00:00:00';
    } catch (e) {
      return 'ERROR:MAC';
    }
  }

  static String generateKey() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  static Future<void> register() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mac = await getMac();
      
      // نحفظو الـ key كان أول مرة فقط
      String? key = prefs.getString('device_key');
      if (key == null) {
        key = generateKey();
        await prefs.setString('device_key', key);
      }
      
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      await Supabase.instance.client.from('devices').upsert({
        'mac_address': mac,
        'activation_key': key,
        'last_seen': DateTime.now().toIso8601String(),
        'device_name': androidInfo.model ?? 'Android TV',
      }, onConflict: 'mac_address');
      
      print('✅ Registered: $mac - $key');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}
