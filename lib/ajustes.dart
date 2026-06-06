import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AjustesScreen extends StatefulWidget {
  @override
  _AjustesScreenState createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {

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
}
