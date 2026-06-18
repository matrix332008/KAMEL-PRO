import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'lang.dart';
import 'main.dart';
import 'speed_test.dart';

class AjustesScreen extends StatefulWidget {
  @override
  _AjustesScreenState createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  String _currentLang = 'ar';
  String _mac = 'AA:BB:CC:DD:EE:FF';
  String _deviceId = '000000';
  String _deviceName = 'ANDROID TV';
  String _expiry = '';

  @override
  void initState() {
    super.initState();
    _loadLang();
    _getDeviceInfo();
  }

  _loadLang() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lang = prefs.getString('lang') ?? 'ar';
    await Lang.set(lang);
    setState(() => _currentLang = lang);
  }

  _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final prefs = await SharedPreferences.getInstance();
    
    String mac = await getMacAddress();
    String deviceId = prefs.getString('device_id') ?? '000000';
    
    print('🔥 AJUSTES MAC: $mac');
    print('🔥 AJUSTES ID: $deviceId');
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        setState(() {
          _deviceName = '${androidInfo.manufacturer} ${androidInfo.model}'.toUpperCase();
          _deviceId = deviceId;
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
        _deviceName = 'ANDROID TV';
        _mac = mac;
        _deviceId = deviceId;
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
        _langOption('🇹🇳','عربي','ar'), 
        _langOption('🇫🇷','Français','fr'),
        _langOption('🇨🇿','Čeština','cs'), 
        _langOption('🇬🇧','English','en'),
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

  Future<void> _checkForUpdate() async {
    String title = {'ar':'تحديث','fr':'Mise à jour','en':'Update','de':'Update','cs':'Aktualizace'}[_currentLang]!;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.cyan),
            SizedBox(height: 16),
            Text({'ar':'جاري البحث عن تحديث...','fr':'Recherche de mise à jour...','en':'Checking for update...','de':'Suche nach Updates...','cs':'Kontrola aktualizace...'}[_currentLang]!, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentVersion = int.parse(packageInfo.buildNumber);
      
      print('🔥 CURRENT VERSION: $currentVersion');

      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/matrix332008/KAMEL-PRO/main/version.json'));
      
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int newVersion = data['versionCode'];
        String apkUrl = data['apkUrl'];
        String newNotes = data['notes'];
        String newSha256 = data['sha256'];

        print('🔥 NEW VERSION: $newVersion');

        if (newVersion > currentVersion) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Color(0xFF1A1A2E),
              title: Text('$title ${data['versionName']}', style: TextStyle(color: Colors.white)),
              content: Text(newNotes, style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text({'ar':'لاحقا','fr':'Plus tard','en':'Later','de':'Später','cs':'Později'}[_currentLang]!, style: TextStyle(color: Colors.white70, fontSize: 18)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _downloadAndInstallApk(apkUrl, newSha256);
                  },
                  child: Text({'ar':'حدّث الآن','fr':'Mettre à jour','en':'Update Now','de':'Jetzt aktualisieren','cs':'Aktualizovat'}[_currentLang]!, style: TextStyle(color: Colors.green, fontSize: 18)),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text({'ar':'التطبيق محدّث لآخر نسخة','fr':'Application à jour','en':'App is up to date','de':'App ist aktuell','cs':'Aplikace je aktuální'}[_currentLang]!), backgroundColor: Colors.green),
          );
        }
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text({'ar':'فشل الاتصال بالسيرفر','fr':'Échec de connexion','en':'Connection failed','de':'Verbindung fehlgeschlagen','cs':'Připojení selhalo'}[_currentLang]!), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _downloadAndInstallApk(String url, String expectedSha256) async {
    final deviceInfo = DeviceInfoPlugin();
    int sdkInt = 30;
    if (Platform.isAndroid) {
      sdkInt = (await deviceInfo.androidInfo).version.sdkInt;
    }

    // Android 8+ يحتاج permission خاص
    if (sdkInt >= 26) {
      var installStatus = await Permission.requestInstallPackages.status;
      if (!installStatus.isGranted) {
        installStatus = await Permission.requestInstallPackages.request();
      }
      if (!installStatus.isGranted) {
        openAppSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text({'ar':'لازم تفعل Install unknown apps','fr':'Activez Install unknown apps','en':'Enable Install unknown apps','de':'Aktivieren Sie Unbekannte Apps installieren','cs':'Povolte Instalace neznámých aplikací'}[_currentLang]!), backgroundColor: Colors.orange),
        );
        return;
      }
    } else {
      // Android 6 و 7
      await Permission.storage.request();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.cyan),
            SizedBox(height: 16),
            Text({'ar':'جاري تحميل التحديث...','fr':'Téléchargement...','en':'Downloading update...','de':'Update wird heruntergeladen...','cs':'Stahování aktualizace...'}[_currentLang]!, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;

      final calculatedSha256 = sha256.convert(bytes).toString();
      if (calculatedSha256 != expectedSha256) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text({'ar':'خطأ: الملف معطوب','fr':'Fichier corrompu','en':'File corrupted','de':'Datei beschädigt','cs':'Soubor je poškozen'}[_currentLang]!), backgroundColor: Colors.red),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kamelpro_update.apk');
      await file.writeAsBytes(bytes);

      Navigator.pop(context);
      
      PackageInfo info = await PackageInfo.fromPlatform();
      final result = await InstallPlugin.installApk(file.path, info.packageName);
      print('Install result: $result');
      
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${{'ar':'فشل التحميل','fr':'Échec du téléchargement','en':'Download failed','de':'Download fehlgeschlagen','cs':'Stahování selhalo'}[_currentLang]!}: $e'), backgroundColor: Colors.red),
      );
    }
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

    final qrData = 'MAC:$_mac\nID:$_deviceId\nEXP:$_expiry';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)])),
        child: Column(children: [
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return SizedBox(height: 40);
              return Container(
                padding: EdgeInsets.only(top: 45),
                child: Text(
                  'BUILD: ${snapshot.data!.version}+${snapshot.data!.buildNumber}',
                  style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          
          Padding(padding: EdgeInsets.fromLTRB(40,10,30,20),
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
                _bigCircle('assets/update.png', labels['update']!, () => _checkForUpdate()),
                _bigCircle('assets/speed.png', labels['speed']!, ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>SpeedTestScreen()))),
              ]),
            ),
          )),
          
          Padding(padding: EdgeInsets.only(bottom: 35),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 35, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4), 
                    borderRadius: BorderRadius.circular(16), 
                    border: Border.all(color: Colors.cyan.withOpacity(0.3))
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_deviceName, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('MAC: $_mac', style: TextStyle(color: Colors.cyan, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    SizedBox(height: 6),
                    Text('ID: $_deviceId   •   Exp: $_expiry', style: TextStyle(color: Colors.white70, fontSize: 15)),
                  ]),
                ),
                
                SizedBox(width: 20),
                
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 2),
                    boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 15)],
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 110,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
