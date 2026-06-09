import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'live_tv.dart';
import 'filmes.dart';
import 'series.dart';
import 'favorites.dart';
import 'ajustes.dart';
import 'login.dart';
import 'lang.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Supabase.initialize(
    url: 'https://jzusqopbxyltavjrxmuc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp6dXNxb3BieHlsdGF2anJ4bXVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1NTMwMjAsImV4cCI6MjA2ODEyOTAyMH0.nW-0RJSdQg_GSHTlOJTP-9w-PRQfH5hgxq-hF_gQpGU',
  );
  await Lang.load();
  runApp(KamelProApp());
}

Future<String> getMacAddress() async {
  try {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      String id = androidInfo.id + androidInfo.model;
      String hex = sha1.convert(utf8.encode(id)).toString().substring(0, 12).toUpperCase();
      return hex.replaceAllMapped(RegExp(r'.{2}'), (m) => '${m.group(0)}:').substring(0,17);
    }
    return 'UNKNOWN';
  } catch (e) {
    return 'ERROR';
  }
}

String generateKey() {
  final random = Random();
  return (100000 + random.nextInt(900000)).toString();
}

Future<void> registerDevice() async {
  try {
    final mac = await getMacAddress();
    final key = generateKey();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_mac', mac);
    await prefs.setString('device_key', key);
    await Supabase.instance.client.from('devices').upsert({
      'mac_address': mac,
      'activation_key': key,
      'last_seen': DateTime.now().toIso8601String(),
    }, onConflict: 'mac_address');
  } catch (e) {
    print('Error: $e');
  }
}

class KamelProApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      child: MaterialApp(
        title: 'KAMEL PRO',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
        ),
        home: SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  _checkLogin() async {
    await registerDevice();
    await Future.delayed(Duration(seconds: 2));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn')?? false;
    if (isLoggedIn) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainMenu()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginSelection()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpeg', fit: BoxFit.fill),
          Center(child: Image.asset('assets/logo.png', width: 300)),
        ],
      ),
    );
  }
}

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  String _expiry = '';
  int _daysLeft = 0;

  @override
  void initState() {
    super.initState();
    _loadExpiry();
  }

  _loadExpiry() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // FIX: ما عادش نحط 7/6/2027 - ناخو من السيرفر فقط
    String expiry = prefs.getString('expiry')?? '';
    int daysLeft = prefs.getInt('daysLeft')?? 0;

    if (expiry.isNotEmpty) {
      try {
        final parts = expiry.split('/');
        final expDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        final now = DateTime.now();
        final diff = expDate.difference(DateTime(now.year, now.month, now.day)).inDays;
        setState(() {
          _expiry = expiry;
          _daysLeft = diff > 0? diff : 0;
        });
      } catch (e) {
        setState(() {
          _expiry = expiry;
          _daysLeft = daysLeft;
        });
      }
    } else {
      setState(() {
        _expiry = '';
        _daysLeft = 0;
      });
    }
  }

  _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('loginType');
    await prefs.remove('server');
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.remove('m3uUrl');
    await prefs.remove('expiry');
    await prefs.remove('daysLeft');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginSelection()));
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(Lang.get('logout_title'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(Lang.get('logout_msg'), style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(Lang.get('no'), style: TextStyle(color: Colors.white70, fontSize: 18))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(Lang.get('yes'), style: TextStyle(color: Colors.redAccent, fontSize: 18))),
        ],
      ),
    )?? false;
  }

  @override
  Widget build(BuildContext context) {
    Color expiryColor = _daysLeft > 30? Colors.green : _daysLeft > 7? Colors.orange : Colors.red;
    String daysText = _expiry.isEmpty? '--' : (_daysLeft > 0? '$_daysLeft يوم' : 'انتهى');

    return WillPopScope(
      onWillPop: () async {
        if (await _showExitDialog(context)) {
          SystemNavigator.pop();
        }
        return false;
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/background.jpeg', fit: BoxFit.fill),
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          CircleAvatar(radius: 30, backgroundImage: AssetImage('assets/avatar.png')),
                          SizedBox(height: 5),
                          if (_expiry.isNotEmpty) // نوريه كان كي يكون موجود
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: expiryColor.withOpacity(0.8), width: 1.5),
                              boxShadow: [BoxShadow(color: expiryColor.withOpacity(0.3), blurRadius: 8)],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _expiry,
                                  style: TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                                Text(
                                  daysText,
                                  style: TextStyle(color: expiryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      _LogoutButton(onPressed: () => _logout(context)),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MainCard(title: Lang.get('live').toUpperCase(), image: 'assets/live.png', color: Colors.blue, autofocus: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTV()))),
                        SizedBox(width: 40),
                        _MainCard(title: Lang.get('movies').toUpperCase(), image: 'assets/filmes.png', color: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilmesScreen()))),
                        SizedBox(width: 40),
                        _MainCard(title: Lang.get('series').toUpperCase(), image: 'assets/series.png', color: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesScreen()))),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 30, left: 60, right: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BottomButton(imagePath: 'assets/favorites.png', label: Lang.get('fav').toUpperCase(), color: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesScreen()))),
                      Row(children: [FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 20), SizedBox(width: 8), Text('WhatsApp +420 777099379', style: TextStyle(color: Colors.white70))]),
                      _LanguageButton(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AjustesScreen()))),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MainCard extends StatefulWidget {
  final String title;
  final String image;
  final Color color;
  final VoidCallback onTap;
  final bool autofocus;

  _MainCard({required this.title, required this.image, required this.color, required this.onTap, this.autofocus = false});

  @override
  __MainCardState createState() => __MainCardState();
}

class __MainCardState extends State<_MainCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 300,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color, width: _focused? 4 : 2),
            boxShadow: _focused? [BoxShadow(color: widget.color, blurRadius: 30, spreadRadius: 5)] : [],
            image: DecorationImage(image: AssetImage(widget.image), fit: BoxFit.cover),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18))),
              child: Text(widget.title, textAlign: TextAlign.center, style: TextStyle(color: widget.color, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomButton extends StatefulWidget {
  final String imagePath;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _BottomButton({required this.imagePath, required this.label, required this.color, required this.onTap});

  @override
  __BottomButtonState createState() => __BottomButtonState();
}

class __BottomButtonState extends State<_BottomButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _focused? Colors.black.withOpacity(0.6) : Colors.transparent,
            border: Border.all(color: _focused? widget.color : Colors.transparent, width: 3),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _focused? [BoxShadow(color: widget.color.withOpacity(0.7), blurRadius: 20)] : [],
          ),
          child: Column(
            children: [
              Image.asset(widget.imagePath, width: 70, height: 70, fit: BoxFit.contain),
              SizedBox(height: 8),
              Text(widget.label, style: TextStyle(color: _focused? widget.color : Colors.white70, fontSize: 18, fontWeight: _focused? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatefulWidget {
  final VoidCallback onTap;
  _LanguageButton({required this.onTap});

  @override
  __LanguageButtonState createState() => __LanguageButtonState();
}

class __LanguageButtonState extends State<_LanguageButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _focused? Colors.black.withOpacity(0.6) : Colors.transparent,
            border: Border.all(color: _focused? Colors.amber : Colors.transparent, width: 3),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _focused? [BoxShadow(color: Colors.amber.withOpacity(0.7), blurRadius: 20)] : [],
          ),
          child: Column(
            children: [
              Image.asset('assets/ajustes.png', width: 70, height: 70, fit: BoxFit.contain),
              SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🇹🇳', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 4),
                  Text('🇫🇷', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 4),
                  Text('🇨🇿', style: TextStyle(fontSize: 20)),
                ],
              ),
              SizedBox(height: 2),
              Text(Lang.get('settings').toUpperCase(), style: TextStyle(color: _focused? Colors.amber : Colors.white70, fontSize: 18, fontWeight: _focused? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final VoidCallback onPressed;
  _LogoutButton({required this.onPressed});

  @override
  __LogoutButtonState createState() => __LogoutButtonState();
}

class __LogoutButtonState extends State<_LogoutButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: OutlinedButton(
        onPressed: widget.onPressed,
        style: OutlinedButton.styleFrom(side: BorderSide(color: _focused? Colors.white : Colors.white70, width: _focused? 3 : 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: Text('LOG OUT', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}
