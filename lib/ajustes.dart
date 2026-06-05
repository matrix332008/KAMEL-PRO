import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AjustesScreen extends StatefulWidget {
  @override
  _AjustesScreenState createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  String _player = 'vlc';
  @override
  void initState() { super.initState(); _load(); }
  _load() async { final p = await SharedPreferences.getInstance(); setState(() => _player = p.getString('player')?? 'vlc'); }
  _save(v) async { final p = await SharedPreferences.getInstance(); await p.setString('player', v); setState(() => _player = v); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(image: DecorationImage(image: AssetImage('assets/background.jpeg'), fit: BoxFit.cover)),
        child: Column(children: [
          Padding(padding: EdgeInsets.all(30), child: Row(children: [IconButton(icon: Icon(Icons.arrow_back, color: Colors.white, size: 35), onPressed: () => Navigator.pop(context)), SizedBox(width: 20), Text('AJUSTES', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))])),
          Spacer(),
          Text('اختر المشغل', style: TextStyle(color: Colors.cyanAccent, fontSize: 26)),
          SizedBox(height: 50),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _card('VLC PLAYER', 'يخدم كل الصيغ', Icons.play_circle_filled, Colors.orange, 'vlc', true),
            SizedBox(width: 60),
            _card('EXO PLAYER', 'أسرع لـ http', Icons.hd, Colors.cyan, 'exo', false),
          ]),
          Spacer(flex: 2),
        ]),
      ),
    );
  }

  Widget _card(t, s, ic, c, v, af) {
    bool sel = _player == v;
    return Focus(
      autofocus: af,
      onKeyEvent: (n, e) { if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.select || e.logicalKey == LogicalKeyboardKey.enter)) { _save(v); return KeyEventResult.handled; } return KeyEventResult.ignored; },
      child: GestureDetector(
        onTap: () => _save(v),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 320, height: 220,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20), border: Border.all(color: sel? c : Colors.white24, width: sel? 4 : 2)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(ic, size: 70, color: c), SizedBox(height: 15),
            Text(t, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(s, style: TextStyle(color: Colors.white70)),
            if (sel) Icon(Icons.check_circle, color: c, size: 30),
          ]),
        ),
      ),
    );
  }
}
