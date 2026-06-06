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
        title: Text('خروج', style: TextStyle(color: Colors.white)),
        content: Text('هل تريد الخروج من التطبيق؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('لا', style: TextStyle(color: Colors.white70))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('نعم', style: TextStyle(color: Colors.redAccent))),
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
                          // القلب الكبير
                          _btnImg('assets/favorites.png', Lang.get('fav'), Colors.pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesScreen()))),
                          // الترس الذهبي
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
                Text(label, style: TextStyle(color: has ? Colors.white : Colors.white70, fontSize: 18, fontWeight: has ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          ),
        );
      }),
    );
  }

  // الجديد - للأيقونات بالصور
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
                Text(label, style: TextStyle(color: has ? Colors.white : Colors.white70, fontSize: 18, fontWeight: has ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          ),
        );
      }),
    );
  }
}
