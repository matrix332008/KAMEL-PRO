import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'player.dart';

class FilmesScreen extends StatefulWidget {
  @override
  _FilmesScreenState createState() => _FilmesScreenState();
}

class _FilmesScreenState extends State<FilmesScreen> {
  List<dynamic> _categories = [];
  List<dynamic> _movies = [];
  List<dynamic> _filteredMovies = [];
  int _selectedCategory = 0;
  bool _loading = true;
  String _server = '';
  String _username = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _server = prefs.getString('server')?? '';
    _username = prefs.getString('username')?? '';
    _password = prefs.getString('password')?? '';

    await _loadCategories();
    await _loadMovies();
    setState(() => _loading = false);
  }

  _loadCategories() async {
    try {
      String url = '$_server/player_api.php?username=$_username&password=$_password&action=get_vod_categories';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _categories = json.decode(response.body);
        if (_categories.isNotEmpty) {
          _filterMovies(_categories[0]['category_id']);
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  _loadMovies() async {
    try {
      String url = '$_server/player_api.php?username=$_username&password=$_password&action=get_vod_streams';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _movies = json.decode(response.body);
      }
    } catch (e) {
      print('Error loading movies: $e');
    }
  }

  _filterMovies(String categoryId) {
    setState(() {
      _filteredMovies = _movies.where((m) => m['category_id'] == categoryId).toList();
    });
  }

  _playMovie(dynamic movie) {
    String streamUrl = '$_server/movie/$_username/$_password/${movie['stream_id']}.${movie['container_extension']}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayer(streamUrl: streamUrl, channelName: movie['name']),
      ),
    );
  }

  _addToFavorites(dynamic movie) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('favorite_movies')?? [];
    String movieJson = json.encode(movie);
    if (!favs.contains(movieJson)) {
      favs.add(movieJson);
      await prefs.setStringList('favorite_movies', favs);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت الاضافة للمفضلة ♥️'), backgroundColor: Colors.green),
      );
    }
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
        child: _loading
           ? Center(child: CircularProgressIndicator(color: Colors.red))
            : Row(
                children: [
                  // Categories
                  Container(
                    width: 300,
                    color: Colors.black.withOpacity(0.7),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(20),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: AssetImage('assets/avatar.png'),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'FILMES',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              bool selected = _selectedCategory == index;
                              return Focus(
                                onFocusChange: (hasFocus) {
                                  if (hasFocus) {
                                    setState(() => _selectedCategory = index);
                                    _filterMovies(_categories[index]['category_id']);
                                  }
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedCategory = index);
                                    _filterMovies(_categories[index]['category_id']);
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: selected? Colors.red.withOpacity(0.3) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: selected? Colors.red : Colors.white24,
                                        width: selected? 3 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      _categories[index]['category_name'],
                                      style: TextStyle(
                                        color: selected? Colors.red : Colors.white,
                                        fontSize: 16,
                                        fontWeight: selected? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Movies Grid
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.all(20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: _filteredMovies.length,
                      itemBuilder: (context, index) {
                        var movie = _filteredMovies[index];
                        return Focus(
                          child: GestureDetector(
                            onTap: () => _playMovie(movie),
                            onLongPress: () => _addToFavorites(movie),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.red, width: 2),
                                boxShadow: [BoxShadow(color: Colors.red, blurRadius: 10)],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (movie['stream_icon']!= null && movie['stream_icon']!= '')
                                      Image.network(
                                        movie['stream_icon'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(color: Colors.grey[900], child: Icon(Icons.movie, size: 60, color: Colors.white54)),
                                      )
                                    else
                                      Container(color: Colors.grey[900], child: Icon(Icons.movie, size: 60, color: Colors.white54)),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(8),
                                        color: Colors.black.withOpacity(0.8),
                                        child: Text(
                                          movie['name'],
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
