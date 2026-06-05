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
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _player = p.getString('player')?? 'vlc');
  }

  _save(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('player', v);
    setState(() => _player = v);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم الحفظ: ${v == 'vlc'? 'VLC' : 'EXO'}'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(image: DecorationImage(image: AssetImage('assets/background.jpeg'), fit: BoxFit.cover)),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(30),
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.arrow_back, color: Colors.white, size: 35), onPressed: () => Navigator.pop(context)),
                  SizedBox(width: 20),
                  Text('AJUSTES', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Spacer(),
            Text('اختر المشغل', style: TextStyle(color: Colors.cyanAccent, fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PlayerCard(
                  title: 'VLC PLAYER',
                  subtitle: 'يخدم كل الصيغ',
                  icon: Icons.play_circle_filled,
                  color: Colors.orange,
                  selected: _player == 'vlc',
                  autofocus: true,
                  onSelect: () => _save('vlc'),
                ),
                SizedBox(width: 60),
                _PlayerCard(
                  title: 'EXO PLAYER',
                  subtitle: 'أسرع للـ http',
                  icon: Icons.hd,
                  color: Colors.cyan,
                  selected: _player == 'exo',
                  onSelect: () => _save('exo'),
                ),
              ],
            ),
            Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool autofocus;
  final VoidCallback onSelect;

  _PlayerCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.selected, this.autofocus = false, required this.onSelect});

  @override
  __PlayerCardState createState() => __PlayerCardState();
}

class __PlayerCardState extends State<_PlayerCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 320,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.selected? widget.color : (_focused? widget.color : Colors.white24), width: widget.selected? 4 : (_focused? 3 : 2)),
            boxShadow: _focused || widget.selected? [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 25, spreadRadius: 2)] : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 70, color: widget.color),
              SizedBox(height: 15),
              Text(widget.title, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(widget.subtitle, style: TextStyle(color: Colors.white70)),
              if (widget.selected)...[
                SizedBox(height: 12),
                Icon(Icons.check_circle, color: widget.color, size: 30),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
