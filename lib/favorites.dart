import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'player.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> _favoriteMovies = [];
  List<dynamic> _favoriteChannels = [];
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> movieFavs = prefs.getStringList('favorite_movies')?? [];
    List<String> channelFavs = prefs.getStringList('favorite_channels')?? [];
    
    setState(() {
      _favoriteMovies = movieFavs.map((e) => json.decode(e)).toList();
      _favoriteChannels = channelFavs.map((e) => json.decode(e)).toList();
    });
  }

  _removeFavorite(int index, bool isMovie) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (isMovie) {
      List<String> favs = prefs.getStringList('favorite_movies')?? [];
      favs.removeAt(index);
      await prefs.setStringList('favorite_movies', favs);
    } else {
      List<String> favs = prefs.getStringList('favorite_channels')?? [];
      favs.removeAt(index);
      await prefs.setStringList('favorite_channels', favs);
    }
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/background.jpeg'), fit: BoxFit.cover),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.black.withOpacity(0.7),
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  SizedBox(width: 20),
                  Icon(Icons.favorite, color: Colors.red, size: 30),
                  SizedBox(width: 10),
                  Text('FAVORITOS', style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              height: 60,
              color: Colors.black.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TabButton(text: 'MOVIES', index: 0, selected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                  SizedBox(width: 20),
                  _TabButton(text: 'CHANNELS', index: 1, selected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                ],
              ),
            ),
            Expanded(
              child: _selectedTab == 0? _buildMoviesGrid() : _buildChannelsGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoviesGrid() {
    if (_favoriteMovies.isEmpty) {
      return Center(child: Text('No favorite movies yet ♥️', style: TextStyle(color: Colors.white70, fontSize: 18)));
    }
    return GridView.builder(
      padding: EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.7, crossAxisSpacing: 20, mainAxisSpacing: 20),
      itemCount: _favoriteMovies.length,
      itemBuilder: (context, index) {
        var movie = _favoriteMovies[index];
        return GestureDetector(
          onTap: () {
            SharedPreferences.getInstance().then((prefs) {
              String server = prefs.getString('server')?? '';
              String user = prefs.getString('username')?? '';
              String pass = prefs.getString('password')?? '';
              String url = '$server/movie/$user/$pass/${movie['stream_id']}.${movie['container_extension']}';
              Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayer(streamUrl: url, channelName: movie['name'])));
            });
          },
          onLongPress: () => _removeFavorite(index, true),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red, width: 2),
                  boxShadow: [BoxShadow(color: Colors.red, blurRadius: 10)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: movie['stream_icon']!= null? Image.network(movie['stream_icon'], fit: BoxFit.cover) : Container(color: Colors.grey[900], child: Icon(Icons.movie, size: 60, color: Colors.white54)),
                ),
              ),
              Positioned(top: 5, right: 5, child: Icon(Icons.favorite, color: Colors.red, size: 30)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChannelsGrid() {
    if (_favoriteChannels.isEmpty) {
      return Center(child: Text('No favorite channels yet ♥️', style: TextStyle(color: Colors.white70, fontSize: 18)));
    }
    return GridView.builder(
      padding: EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 1.5, crossAxisSpacing: 20, mainAxisSpacing: 20),
      itemCount: _favoriteChannels.length,
      itemBuilder: (context, index) {
        var channel = _favoriteChannels[index];
        return GestureDetector(
          onTap: () {
            SharedPreferences.getInstance().then((prefs) {
              String server = prefs.getString('server')?? '';
              String user = prefs.getString('username')?? '';
              String pass = prefs.getString('password')?? '';
              String url = '$server/live/$user/$pass/${channel['stream_id']}.m3u8';
              Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayer(streamUrl: url, channelName: channel['name'])));
            });
          },
          onLongPress: () => _removeFavorite(index, false),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.cyan, width: 2),
                  boxShadow: [BoxShadow(color: Colors.cyan, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (channel['stream_icon']!= null) Image.network(channel['stream_icon'], height: 60) else Icon(Icons.tv, size: 60, color: Colors.white54),
                    SizedBox(height: 10),
                    Text(channel['name'], textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              Positioned(top: 5, right: 5, child: Icon(Icons.favorite, color: Colors.red, size: 30)),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  
  _TabButton({required this.text, required this.index, required this.selected, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        decoration: BoxDecoration(
          color: selected? Colors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
