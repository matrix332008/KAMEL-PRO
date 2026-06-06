import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'player.dart';

class FavoritesService {
  static const _key = 'favorites';

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?? [];
  }

  Future<Set<String>> getFavoriteUrls() async {
    final favs = await getFavorites();
    return favs.map((e) => e.split('|').last).toSet();
  }

  Future<void> toggle(String name, String url) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(_key)?? [];
    final item = '$name|$url';
    if (favs.contains(item)) {
      favs.remove(item);
    } else {
      favs.add(item);
    }
    await prefs.setStringList(_key, favs);
  }

  Future<bool> isFavorite(String url) async {
    final urls = await getFavoriteUrls();
    return urls.contains(url);
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
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 20),
                  Text(
                    'FAVORITOS',
                    style: TextStyle(color: Colors.red, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: favorites.isEmpty
                 ? Center(child: Text('No favorites yet', style: TextStyle(color: Colors.white70, fontSize: 20)))
                  : ListView.builder(
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        var item = favorites[index].split('|');
                        return ListTile(
                          title: Text(item[0], style: TextStyle(color: Colors.white)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlayerScreen(url: item[1], title: item[0]),
                              ),
                            );
                          },
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
