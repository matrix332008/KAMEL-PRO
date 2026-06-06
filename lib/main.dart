import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'live_tv.dart';
import 'epg.dart';
import 'filmes.dart';
import 'series.dart';
import 'favorites.dart';
import 'ajustes.dart';
import 'login.dart';
import 'lang.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Lang.load();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(KamelProApp());
}

class KamelProApp extends StatefulWidget {
  static _KamelProAppState? of(BuildContext context) => context.findAncestorStateOfType<_KamelProAppState>();
  @override _KamelProAppState createState() => _KamelProAppState();
}

class _KamelProAppState extends State<KamelProApp> {
  void restart() => setState(() {});
  @override Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      child: MaterialApp(
        title: 'KAMEL PRO',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
        home: SplashScreen(),
      ),
    );
  }
}

// SPLASH - تم التعديل: يقرا الاشتراك حتى بدون isLoggedIn
class SplashScreen extends StatefulWidget { @override _SplashScreenState createState() => _SplashScreenState(); }
class _SplashScreenState extends State<SplashScreen> {
  @override void initState() { super.initState(); _checkLogin(); }
  _checkLogin() async {
    await Future.delayed(Duration(seconds: 2));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('server_url') ?? prefs.getString('server');
    String? user = prefs.getString('username');
    String? pass = prefs.getString('password');
    if (url != null && url.isNotEmpty && user != null && user.isNotEmpty && pass != null && pass.isNotEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainMenu()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginSelection()));
    }
  }
  @override Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/background.jpeg', fit: BoxFit.fill),
        Center(child: Image.asset('assets/logo.png', width: 300)),
      ]),
    );
  }
}

// MAIN MENU - تم التعديل: الخروج ما يفسخش المعطيات
class MainMenu extends StatefulWidget { @override _MainMenuState createState() => _MainMenuState(); }
class _MainMenuState extends State<MainMenu> {
  
  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(Lang.get('logout_title'), style: TextStyle(color: Colors.white)),
        content: Text(Lang.get('logout_msg'), style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(Lang.get('no'), style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(Lang.get('yes'), style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }

  void _exitApp() {
    SystemNavigator.pop(); // تم التعديل: خروج فقط، ما يمسحش
  }

  @override Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool exit = await _onWillPop();
        if (exit) _exitApp();
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
                  child: Row(children: [
                    CircleAvatar(radius: 30, backgroundImage: AssetImage('assets/avatar.png')),
                    SizedBox(width: 20),
                    Image.asset('assets/logo.png', width: 200),
                    Spacer(),
                    _LogoutButton(onPressed: () async {
                      bool exit = await _onWillPop();
                      if (exit) _exitApp();
                    }),
                  ]),
                ),
                Expanded(
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _MainCard(title: Lang.get('live'), image: 'assets/live.png', color: Colors.blue, autofocus: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTV()))),
                        SizedBox(width: 40),
                        _MainCard(title: Lang.get('epg'), image: 'assets/epg.png', color: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EPGScreen()))),
                      ]),
                      SizedBox(height: 40),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _MainCard(title: Lang.get('movies'), image: 'assets/filmes.png', color: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilmesScreen()))),
                        SizedBox(width: 40),
                        _MainCard(title: Lang.get('series'), image: 'assets/series.png', color: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesScreen()))),
                      ]),
                    ]),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 30, left: 60, right: 60),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _BottomButton(icon: Icons.favorite, label: Lang.get('fav'), color: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesScreen()))),
                    Row(children: [FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 20), SizedBox(width: 8), Text('WhatsApp +420 777099379', style: TextStyle(color: Colors.white70))]),
                    _LanguageButton(onTap: () async { 
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => AjustesScreen())); 
                      KamelProApp.of(context)?.restart();
                      setState((){});
                    }),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// باقي الكلاسات نفسهم بدون تغيير
class _MainCard extends StatefulWidget {
  final String title; final String image; final Color color; final VoidCallback onTap; final bool autofocus;
  _MainCard({required this.title, required this.image, required this.color, required this.onTap, this.autofocus = false});
  @override __MainCardState createState() => __MainCardState();
}
class __MainCardState extends State<_MainCard> {
  bool _focused = false;
  @override Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onTap(); return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 300, height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color, width: _focused ? 4 : 2),
            boxShadow: _focused ? [BoxShadow(color: widget.color, blurRadius: 30, spreadRadius: 5)] : [],
            image: DecorationImage(image: AssetImage(widget.image), fit: BoxFit.cover),
          ),
          child: Align(alignment: Alignment.bottomCenter, child: Container(width: double.infinity, padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18))), child: Text(widget.title, textAlign: TextAlign.center, style: TextStyle(color: widget.color, fontSize: 20, fontWeight: FontWeight.bold)))),
        ),
      ),
    );
  }
}

class _BottomButton extends StatefulWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  _BottomButton({required this.icon, required this.label, required this.color, required this.onTap});
  @override __BottomButtonState createState() => __BottomButtonState();
}
class __BottomButtonState extends State<_BottomButton> {
  bool _focused = false;
  @override Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) { widget.onTap(); return KeyEventResult.handled; }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(onTap: widget.onTap, child: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: _focused ? widget.color : Colors.transparent, width: 2), borderRadius: BorderRadius.circular(10)), child: Column(children: [Icon(widget.icon, color: widget.color, size: 40), SizedBox(height: 5), Text(widget.label, style: TextStyle(color: widget.color, fontSize: 14))]))),
    );
  }
}

class _LanguageButton extends StatefulWidget { final VoidCallback onTap; _LanguageButton({required this.onTap}); @override __LanguageButtonState createState() => __LanguageButtonState(); }
class __LanguageButtonState extends State<_LanguageButton> {
  bool _focused = false;
  @override Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) { widget.onTap(); return KeyEventResult.handled; }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(onTap: widget.onTap, child: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: _focused ? Colors.white70 : Colors.transparent, width: 2), borderRadius: BorderRadius.circular(10)), child: Column(children: [Row(children: [Text('🇹🇳', style: TextStyle(fontSize: 24)), SizedBox(width: 5), Text('🇫🇷', style: TextStyle(fontSize: 24)), SizedBox(width: 5), Text('🇨🇿', style: TextStyle(fontSize: 24))]), SizedBox(height: 5), Text(Lang.get('settings'), style: TextStyle(color: Colors.white70, fontSize: 14))]))),
    );
  }
}

class _LogoutButton extends StatefulWidget { final VoidCallback onPressed; _LogoutButton({required this.onPressed}); @override __LogoutButtonState createState() => __LogoutButtonState(); }
class __LogoutButtonState extends State<_LogoutButton> {
  bool _focused = false;
  @override Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) { widget.onPressed(); return KeyEventResult.handled; }
        return KeyEventResult.ignored;
      },
      child: OutlinedButton(onPressed: widget.onPressed, style: OutlinedButton.styleFrom(side: BorderSide(color: _focused ? Colors.white : Colors.white70, width: _focused ? 3 : 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text('EXIT', style: TextStyle(color: Colors.white70))),
    );
  }
}
