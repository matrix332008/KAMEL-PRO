import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'lang.dart';
import 'main.dart';
import 'speed_test.dart';

class AjustesScreen extends StatefulWidget {
  @override
  _AjustesScreenState createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  String _currentLang = 'ar';
  String _mac = '...';
  String _deviceId = '...';
  String _deviceName = '...';
  String _expiry = '';

  @override
  void initState() {
    super.initState();
    _loadLang();
    _getDeviceInfo();
  }

  _loadLang() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _currentLang = prefs.getString('lang') ?? 'ar');
  }

  _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final prefs = await SharedPreferences.getInstance();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        String androidId = androidInfo.id ?? '';
        var digest = sha1.convert(utf8.encode(androidId));
        String hex = digest.toString().substring(0, 12).toUpperCase();
        String mac = hex.replaceAllMapped(RegExp(r'.{2}'), (m) => '${m.group(0)}:');
        mac = mac.substring(0, 17);
        setState(() {
          _deviceName = '${androidInfo.manufacturer} ${androidInfo.model}'.toUpperCase();
          _deviceId = digest.toString().substring(0, 6).toUpperCase();
          _mac = mac;
        });
      }
      if (!prefs.containsKey('expiry')) {
        final expiry = DateTime.now().add(Duration(days: 365));
        await prefs.setString('expiry', '${expiry.day}/${expiry.month}/${expiry.year}');
      }
      setState(() => _expiry = prefs.getString('expiry') ?? '');
    } catch (e) {
      setState(() {
        _deviceName = 'XIAOMI MITV-AYFR0';
        _mac = '45:2A:CD:2F:31:17';
        _deviceId = '452ACD';
        _expiry = '20/9/2026';
      });
    }
  }

  _changeLang(String lang) async {
    await Lang.set(lang);
    setState(() => _currentLang = lang);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => MainMenu()), (route) => false);
  }

  void _showQrBigDialog() {
    String title = {'ar':'امسح للزيارة','fr':'Scannez pour visiter','en':'Scan to visit','de':'Scannen','cs':'Naskenujte'}[_currentLang] ?? 'Scan';
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Color(0xFF1A1A2E),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(title, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        Container(color: Colors.white, padding: EdgeInsets.all(12),
          child: Image.asset('assets/qr_big.png', width: 340, height: 340, fit: BoxFit.contain)),
        SizedBox(height: 12),
        Text('kamelpro.com', style: TextStyle(color: Colors.white70, fontSize: 16)),
      ]),
      actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: Text('OK', style: TextStyle(color: Colors.cyan)))],
    ));
  }

  void _showLangDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Color(0xFF1A1A2E),
      title: Text(Lang.get('choisir_langue'), style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _langOption('🇹🇳','عربي','ar'), _langOption('🇫🇷','Français','fr'),
        _langOption('🇨🇿','Čeština','cs'), _langOption('🇬🇧','English','en'),
        _langOption('🇩🇪','Deutsch','de'),
      ]),
    ));
  }

  Widget _langOption(String flag, String name, String code) => ListTile(
    leading: Text(flag, style: TextStyle(fontSize: 28)),
    title: Text(name, style: TextStyle(color: Colors.white)),
    trailing: _currentLang == code ? Icon(Icons.check, color: Colors.cyan) : null,
    onTap: () { Navigator.pop(context); _changeLang(code); },
  );

  void _showUpdateDialog() {
    String title = {'ar':'تحديث','fr':'Mise à jour','en':'Update','de':'Update','cs':'Aktualizace'}[_currentLang]!;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Color(0xFF1A1A2E),
      title: Text(title, style: TextStyle(color: Colors.white)),
      content: Text('Version: 1.0.0\nkamelpro.com', style: TextStyle(color: Colors.white70)),
      actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: Text('OK', style: TextStyle(color: Colors.cyan)))],
    ));
  }

  Widget _bigCircle(String asset, String label, VoidCallback onTap, {bool autofocus=false}) {
    return Focus(
      autofocus: autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
          onTap(); return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: (ctx) {
        final hasFocus = Focus.of(ctx).hasFocus;
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 150),
            transform: Matrix4.identity()..scale(hasFocus ? 1.12 : 1.0),
            child: Column(children: [
              Container(
                width: 150, height: 150,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  boxShadow: hasFocus ? [BoxShadow(color: Colors.cyan.withOpacity(0.7), blurRadius: 30)] : [BoxShadow(color: Colors.black54, blurRadius: 15)]),
                child: ClipOval(child: Image.asset(asset, fit: BoxFit.cover)),
              ),
              SizedBox(height: 16),
              Text(label, textAlign: TextAlign.center, style: TextStyle(color: hasFocus ? Colors.cyan : Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = {
      'langue': {'ar':'اللغة','fr':'Langue','en':'Language','de':'Sprache','cs':'Jazyk'}[_currentLang]!,
      'qr': 'QR',
      'update': {'ar':'تحديث','fr':'Mise à jour','en':'Update','de':'Update','cs':'Aktualizace'}[_currentLang]!,
      'speed': {'ar':'اختبار سرعة الانترنت','fr':'Test vitesse','en':'Speed Test','de':'Speedtest','cs':'Test rychlosti'}[_currentLang]!,
    };

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)])),
        child: Column(children: [
          Padding(padding: EdgeInsets.fromLTRB(40,50,30,20),
            child: Row(children: [
              IconButton(icon: Icon(Icons.arrow_back, color: Colors.white, size: 32), onPressed: ()=>Navigator.pop(context)),
              SizedBox(width: 15),
              Text(Lang.get('settings'), style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ]),
          ),
          Expanded(child: Center(
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 60),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _bigCircle('assets/globe.png', labels['langue']!, _showLangDialog, autofocus: true),
                _bigCircle('assets/qr.png', labels['qr']!, _showQrBigDialog),
                _bigCircle('assets/update.png', labels['update']!, _showUpdateDialog),
                _bigCircle('assets/speed.png', labels['speed']!, ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>SpeedTestScreen()))),
              ]),
            ),
          )),
          Padding(padding: EdgeInsets.only(bottom: 35),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 35, vertical: 20),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.cyan.withOpacity(0.3))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_deviceName, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('MAC: $_mac', style: TextStyle(color: Colors.cyan, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                SizedBox(height: 6),
                Text('ID: $_deviceId   •   Exp: $_expiry', style: TextStyle(color: Colors.white70, fontSize: 15)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
