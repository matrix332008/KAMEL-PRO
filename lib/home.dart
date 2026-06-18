import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_id/android_id.dart';
import 'live_tv.dart';
import 'filmes.dart';
import 'series.dart';
import 'favorites.dart';
import 'ajustes.dart';
import 'epg.dart';
import 'lang.dart';

class HomeScreen extends StatefulWidget {
  @override _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _macAddress = '00:00:00:00';
  String _deviceId = '000000';

  @override
  void initState() {
    super.initState();
    Lang.load().then((_) => setState(() {}));
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final androidId = await AndroidId().getId() ?? '000000';
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final mac = androidInfo.id;
    setState(() {
      _deviceId = androidId;
      _macAddress = mac;
    });
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(Lang.get('exit'), style: TextStyle(color: Colors.white)),
        content: Text(Lang.get('exit_msg'), style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(Lang.get('no'), style: TextStyle(color: Colors.white70))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(Lang.get('yes'), style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    ) ?? false;
  }

  void _changeLang() async {
    final langs = {
      'ar': 'العربية',
      'en': 'English',
      'fr': 'Français',
      'es': 'Español',
      'de': 'Deutsch',
    };
    final selected = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text('Language / اللغة', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: langs.entries.map((e) => ListTile(
            title: Text(e.value, style: TextStyle(color: Colors.white70)),
            trailing: Lang.current == e.key ? Icon(Icons.check, color: Colors.cyanAccent) : null,
            onTap: () => Navigator.pop(c, e.key),
          )).toList(),
        ),
      ),
    );
    if (selected != null && selected != Lang.current) {
      await Lang.setLang(selected);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = 'MAC:$_macAddress\nID:$_deviceId';
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _showExitDialog()) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.jpeg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
                ),
              ),
            ),

            // MANUAL REGISTRATION - هبطناها شوي
            Positioned(
              top: MediaQuery.of(context).size.height * 0.41,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'MANUAL REGISTRATION',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                  ),
                ),
              ),
            ),
            
            // 1. ايقونة اللغة فوق على اليمين
            Positioned(
              top: 40,
              right: 40,
              child: SafeArea(
                child: Focus(
                  child: Builder(builder: (ctx) {
                    final has = Focus.of(ctx).hasFocus;
                    return GestureDetector(
                      onTap: _changeLang,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 150),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: has ? Colors.blue.withOpacity(0.3) : Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: has ? Colors.blue : Colors.white24, width: has ? 3 : 1),
                        ),
                        child: Icon(Icons.language, color: has ? Colors.blue : Colors.white, size: 32),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // 2. صورتك + QR الصغير + MAC/ID على اليسار الفوق
            Positioned(
              top: 40,
              left: 40,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // صورتك الدائرية
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 2),
                        image: DecorationImage(
                          image: AssetImage('assets/qr_big.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 110, // كبرناه شوي
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.cyanAccent, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MAC: $_macAddress', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('ID: $_deviceId', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. qr_big.png اكبر + على اليمين لوطا
            Positioned(
              bottom: 30,
              right: 30,
              child: Image.asset(
                'assets/qr_big.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),

            // KAMEL PRO الأخضر
            Positioned(
              left: 40,
              bottom: 85,
              child: Transform.rotate(
                angle: -0.08,
                child: Text(
                  'KAMEL PRO',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00E676),
                    shadows: [
                      Shadow(blurRadius: 12, color: Colors.black87, offset: Offset(3,3)),
                      Shadow(blurRadius: 20, color: Colors.greenAccent.withOpacity(0.4)),
                    ],
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            // واتساب + الرقم
            Positioned(
              bottom: 45,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '+420 777099379',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 40),
                  Center(child: Text('KAMEL PRO', style: TextStyle(color: Colors.red, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 3, shadows: [Shadow(blurRadius: 20, color: Colors.red.withOpacity(0.5))]))),
                  SizedBox(height: 60),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 80),
                      child: GridView.count(
                        crossAxisCount: 3,
                        childAspectRatio: 1.8,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        children: [
                          _btn(Icons.live_tv, Lang.get('live'), Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTV()))),
                          _btn(Icons.movie, Lang.get('movies'), Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilmesScreen()))),
                          _btn(Icons.tv, Lang.get('series'), Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesScreen()))),
                          _btn(Icons.calendar_today, Lang.get('epg'), Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => EPGScreen()))),
                          _btnImg('assets/favorites.png', Lang.get('fav'), Colors.pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesScreen()))),
                          _btnImg('assets/ajustes.png', Lang.get('settings'), Colors.amber, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AjustesScreen()))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Focus(
      autofocus: label == Lang.get('live'),
      child: Builder(builder: (ctx) {
        final has = Focus.of(ctx).hasFocus;
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: has ? color.withOpacity(0.3) : Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: has ? color : Colors.white24, width: has ? 3 : 1),
              boxShadow: has ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 20)] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: has ? color : Colors.white70),
                SizedBox(height: 8),
                Text(label, style: TextStyle(color: has ? Colors.white : Colors.white70, fontSize: 18, fontWeight: has ? FontWeight.bold : FontWeight.normal, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _btnImg(String asset, String label, Color color, VoidCallback onTap) {
    return Focus(
      child: Builder(builder: (ctx) {
        final has = Focus.of(ctx).hasFocus;
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: has ? color.withOpacity(0.3) : Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: has ? color : Colors.white24, width: has ? 3 : 1),
              boxShadow: has ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 25, spreadRadius: 2)] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(asset, width: 64, height: 64, fit: BoxFit.contain),
                SizedBox(height: 8),
                Text(label, style: TextStyle(color: has ? Colors.white : Colors.white70, fontSize: 18, fontWeight: has ? FontWeight.bold : FontWeight.normal, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
              ],
            ),
          ),
        );
      }),
    );
  }
}
