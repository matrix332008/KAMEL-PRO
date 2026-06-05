import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AjustesScreen extends StatefulWidget {
  @override
  _AjustesScreenState createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  String lang = 'ar';
  String player = 'vlc';

  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      lang = p.getString('lang') ?? 'ar';
      player = p.getString('player') ?? 'vlc';
    });
  }

  _save(String key, String val) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, val);
    setState(() {
      if (key == 'lang') lang = val; else player = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/background.jpeg'), fit: BoxFit.cover),
        ),
        child: Center(
          child: Container(
            width: 700,
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(icon: Icon(Icons.arrow_back, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
                    SizedBox(width: 20),
                    Text('AJUSTES', style: TextStyle(color: Colors.cyan, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 40),
                Text('اختر المشغل', style: TextStyle(color: Colors.white70, fontSize: 22)),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _playerBtn('VLC PLAYER', 'vlc', Icons.play_circle_filled, player == 'vlc'),
                    _playerBtn('EXO PLAYER', 'exo', Icons.smart_display, player == 'exo'),
                  ],
                ),
                SizedBox(height: 40),
                Text('اللغة', style: TextStyle(color: Colors.white70, fontSize: 22)),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _flag('🇹🇳', 'العربية', 'ar'),
                    _flag('🇫🇷', 'Français', 'fr'),
                    _flag('🇨🇿', 'Čeština', 'cz'),
                  ],
                ),
                SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () async {
                    final p = await SharedPreferences.getInstance();
                    await p.clear();
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15)),
                  child: Text('تسجيل الخروج', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _playerBtn(String title, String val, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () => _save('player', val),
      child: Container(
        width: 220,
        padding: EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: selected ? Colors.cyan.withOpacity(0.3) : Colors.black.withOpacity(0.5),
          border: Border.all(color: selected ? Colors.cyan : Colors.white30, width: 3),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, size: 60, color: selected ? Colors.cyan : Colors.white54),
            SizedBox(height: 10),
            Text(title, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            if (selected) Icon(Icons.check_circle, color: Colors.cyan, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _flag(String emoji, String name, String code) {
    final selected = lang == code;
    return GestureDetector(
      onTap: () => _save('lang', code),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? Colors.cyan : Colors.white30, width: 3),
          borderRadius: BorderRadius.circular(12),
          color: selected ? Colors.cyan.withOpacity(0.2) : Colors.transparent,
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 45)),
            SizedBox(height: 5),
            Text(name, style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
