import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DeviceRegister {

  // يولد MAC ثابت بصيغة 02:00:00:XX:XX:XX
  static Future<String> getStableMac() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. شوف كان مخزن قبل
    String? savedMac = prefs.getString('device_mac');
    if (savedMac != null && savedMac.isNotEmpty) {
      print('✅ SAVED MAC: $savedMac');
      return savedMac;
    }

    // 2. ولّد MAC جديد ثابت من ANDROID_ID
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        
        // نستعمل ANDROID_ID + fingerprint باش يكون unique لكل جهاز
        String rawId = androidInfo.id + androidInfo.fingerprint;
        
        // نحولوه لـ sha256 وناخذو اول 6 ارقام
        final bytes = utf8.encode(rawId);
        final digest = sha256.convert(bytes);
        final hex = digest.toString().substring(0, 6).toUpperCase();
        
        // نصنعو MAC يبدا بـ 02:00:00
        String mac = '02:00:00:' + 
                     hex.substring(0, 2) + ':' + 
                     hex.substring(2, 4) + ':' + 
                     hex.substring(4, 6);
        
        await prefs.setString('device_mac', mac);
        print('🔥 NEW MAC GENERATED: $mac');
        return mac;
      }
      return '02:00:00:00';
    } catch (e) {
      print('❌ Error: $e');
      return '02:00:00:00';
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
      final mac = await getStableMac(); // نستعملو MAC مش ID
      final key = await getActivationKey();
      
      await Supabase.instance.client.from('devices').upsert({
        'mac_address': mac, // نحطو MAC هنا
        'activation_key': key,
        'last_seen': DateTime.now().toIso8601String(),
      }, onConflict: 'mac_address');
      
      print('✅ Registered: $mac - $key');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}
