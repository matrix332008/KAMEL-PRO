import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DeviceRegister {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://jzusqopbxyltavjrxmuc.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp6dXNxb3BieHlsdGF2anJ4bXVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1NTMwMjAsImV4cCI6MjA2ODEyOTAyMH0.nW-0RJSdQg_GSHTlOJTP-9w-PRQfH5hgxq-hF_gQpGU',
    );
  }

  static Future<String> getStableId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. كان عندنا ID مخزن من قبل، رجعو طول وما تولدش جديد
    String? savedId = prefs.getString('stable_device_id');
    if (savedId != null && savedId.isNotEmpty) {
      print('✅ STABLE ID FOUND: $savedId');
      return savedId;
    }

    // 2. كان ما فماش، ولد ID ثابت من معلومات الجهاز
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // نستعمل ANDROID_ID + SERIAL باش نضمنو ثابت 100%
        String rawId = androidInfo.id + androidInfo.fingerprint;
        String stableId = sha1.convert(utf8.encode(rawId)).toString().toUpperCase();
        
        // خزنو مرة وحدة مدى الحياة
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
    
    // 1. كان عندنا Key مخزن، رجعو هو بيدو
    String? savedKey = prefs.getString('activation_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      return savedKey;
    }

    // 2. كان لا، ولد واحد جديد وخزنو
    String newKey = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    await prefs.setString('activation_key', newKey);
    return newKey;
  }

  static Future<void> register() async {
    try {
      final id = await getStableId();
      final key = await getActivationKey();
      
      await Supabase.instance.client.from('devices').upsert({
        'mac_address': id, // نستعملو نفس العمود باش ما نبدلوش الداتابيز
        'activation_key': key,
        'last_seen': DateTime.now().toIso8601String(),
      }, onConflict: 'mac_address');
      
      print('✅ Registered: $id - $key');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}
