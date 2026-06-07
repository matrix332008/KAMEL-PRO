import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'player.dart';
import 'lang.dart'; // <-- زدتها

class FavoritesService {
  static const _key = 'favorites';

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?? [];
  }

  Future<Set<String>> getFavoriteUrls() async {
    final favs = await getFavorites();
    return favs.map((e) => e.split('|')[1]).toSet();
  }

  Future<void> toggle(String name, String url, String logo) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(_key)?? [];
    final item = '$name|$url|$logo';
    favs.removeWhere((e) => e.split('|')[1] == url);
    if (!favs.contains(item)) {
      favs.add(item);
    }
    await prefs.setStringList(_key, favs);
  }
}

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<String> favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = prefs.getStringList('favorites')?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Colors.black],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(30, 50, 30, 20),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 15),
                  Image.asset('assets/favorites.png', width: 50, height: 50),
                  SizedBox(width: 15),
                  Text(
                    Lang.get('fav_title'), // <-- تبدل
                    style: TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: favorites.isEmpty
                ? Center(child: Text(Lang.get('no_fav'), style: TextStyle(color: Colors.white70, fontSize: 24))) // <-- تبدل
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        var parts = favorites[index].split('|');
                        var name = parts[0];
                        var url = parts.length > 1? parts[1] : '';
                        var logo = parts.length > 2? parts[2] : '';

                        return Focus(
                          autofocus: index == 0,
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(url: url, title: name, logo: logo)));
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Builder(builder: (ctx) {
                            final hasFocus = Focus.of(ctx).hasFocus;
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 150),
                              margin: EdgeInsets.symmetric(vertical: 8),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: hasFocus? Colors.cyan.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: hasFocus? Colors.cyan : Colors.white24, width: hasFocus? 3 : 1),
                              ),
                              child: Row(
                                children: [
                                  if (logo.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(logo, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.tv, color: Colors.white, size: 50)),
                                    )
                                  else
                                    Icon(Icons.tv, color: Colors.white, size: 50),
                                  SizedBox(width: 25),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        color: hasFocus? Colors.cyan : Colors.white,
                                        fontSize: 26,
                                        fontWeight: hasFocus? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.play_circle_fill, color: hasFocus? Colors.cyan : Colors.white54, size: 40),
                                ],
                              ),
                            );
                          }),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
