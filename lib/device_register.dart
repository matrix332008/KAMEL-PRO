import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DeviceRegister {
  // ✅ حذفنا init() نهائياً - main.dart هو اللي يعمل Initialize

  static Future<String> getStableId() async {
    final prefs = await SharedPreferences.getInstance();
    
    String? savedId = prefs.getString('stable_device_id');
    if (savedId != null && savedId.isNotEmpty) {
      print('✅ STABLE ID FOUND: $savedId');
      return savedId;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        String rawId = androidInfo.id + androidInfo.fingerprint;
        String stableId = sha1.convert(utf8.encode(rawId)).toString().toUpperCase();
        
        await prefs.setString('stable_device_id', stableId);
        print('🔥 NEW STABLE ID GENERATED: $stableId');
        return stableId;
      }
      return 'UNKNOWN_DEVICE';
    } catch (e) {
      print('❌ Error generating ID: $e');
      return 'ERROR_DEVICE';
    }
  }

  static Future<String> getActivationKey() async {
    final prefs = await SharedPreferences.getInstance();
    
    String? savedKey = prefs.getString('activation_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      return savedKey;
    }

    String newKey = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    await prefs.setString('activation_key', newKey);
    return newKey;
  }

  static Future<void> register() async {
    try {
      final id = await getStableId();
      final key = await getActivationKey();
      
      await Supabase.instance.client.from('devices').upsert({
        'mac_address': id,
        'activation_key': key,
        'last_seen': DateTime.now().toIso8601String(),
      }, onConflict: 'mac_address');
      
      print('✅ Registered: $id - $key');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}
