import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lang.dart';

class AjustesScreen extends StatefulWidget {
  @override
  _AjustesScreenState createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  String _currentLang = 'ar';

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  _loadLang() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLang = prefs.getString('lang') ?? 'ar';
    });
  }

  _changeLang(String lang) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
    await Lang.load();
    setState(() => _currentLang = lang);
    // رجوع للصفحة الرئيسية باش يتبدل كل شي
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('AJUSTES'),
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إعدادات المشغل', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            _infoCard(),
            SizedBox(height: 30),
            Text('اللغة / Langue / Jazyk', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _langBtn('🇹🇳', 'عربي', 'ar'),
                _langBtn('🇫🇷', 'Français', 'fr'),
                _langBtn('🇨🇿', 'Čeština', 'cs'),
              ],
            ),
            Spacer(),
            Text('KAMEL PRO v1.0', style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Focus(
      autofocus: true,
      child: Builder(
        builder: (ctx) {
          final hasFocus = Focus.of(ctx).hasFocus;
          return Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hasFocus ? Colors.cyan : Colors.white24, width: hasFocus ? 3 : 2),
            ),
            child: Row(
              children: [
                Icon(Icons.play_circle_fill, color: Colors.cyan, size: 48),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Exo Player', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('مشغل موحد لجميع المحتويات - لايف، أفلام ومسلسلات', style: TextStyle(color: Colors.white70, fontSize: 15)),
                      SizedBox(height: 8),
                      Text('✓ أداء أفضل  ✓ بدون تقطيع', style: TextStyle(color: Colors.greenAccent, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _langBtn(String flag, String name, String code) {
    bool selected = _currentLang == code;
    return Focus(
      child: Builder(
        builder: (ctx) {
          final hasFocus = Focus.of(ctx).hasFocus;
          return GestureDetector(
            onTap: () => _changeLang(code),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 110,
              padding: EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: selected ? Colors.amber.withOpacity(0.2) : Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: hasFocus ? Colors.amber : (selected ? Colors.amber : Colors.white24), width: hasFocus || selected ? 3 : 1),
                boxShadow: hasFocus ? [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 15)] : [],
              ),
              child: Column(
                children: [
                  Text(flag, style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text(name, style: TextStyle(color: selected || hasFocus ? Colors.amber : Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
