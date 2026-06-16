import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  @override
  void initState() {
    super.initState();
    Lang.load().then((_) => setState(() {}));
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(Lang.get('exit'), style: TextStyle(color: Colors.white)), // ← تبدل
        content: Text(Lang.get('exit_msg'), style: TextStyle(color: Colors.white70)), // ← تبدل
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(Lang.get('no'), style: TextStyle(color: Colors.white70))), // ← تبدل
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(Lang.get('yes'), style: TextStyle(color: Colors.redAccent))), // ← تبدل
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
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
