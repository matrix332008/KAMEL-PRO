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

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _player = p.getString('player') ?? 'vlc');
  }

  Future<void> _save(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('player', v);
    setState(() => _player = v);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الحفظ: $v'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text('AJUSTES'), leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اختر المشغل', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            _card('vlc', 'VLC Player', 'الأفضل للقنوات المباشرة', Icons.live_tv, Colors.orange),
            SizedBox(height: 12),
            _card('exo', 'Exo Player', 'الأفضل للأفلام والمسلسلات', Icons.movie, Colors.cyan),
          ],
        ),
      ),
    );
  }

  Widget _card(String v, String t, String d, IconData ic, Color c) {
    final sel = _player == v;
    return Focus(
      autofocus: v == 'vlc',
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
          _save(v);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final hasFocus = Focus.of(ctx).hasFocus;
          return GestureDetector(
            onTap: () => _save(v),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 150),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sel ? c.withOpacity(0.2) : Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: hasFocus ? Colors.white : (sel ? c : Colors.white24), width: hasFocus ? 3 : 2),
              ),
              child: Row(
                children: [
                  Icon(ic, color: sel ? c : Colors.white70, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(d, style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  if (sel) Icon(Icons.check_circle, color: c),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
