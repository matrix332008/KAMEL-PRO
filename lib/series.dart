import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'player.dart';

class SeriesScreen extends StatefulWidget {
  @override
  _SeriesScreenState createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  List<dynamic> _categories = [];
  List<dynamic> _series = [];
  List<dynamic> _filteredSeries = [];
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
    await _loadSeries();
    setState(() => _loading = false);
  }

  _loadCategories() async {
    try {
      String url = '$_server/player_api.php?username=$_username&password=$_password&action=get_series_categories';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _categories = json.decode(response.body);
        if (_categories.isNotEmpty) {
          _filterSeries(_categories[0]['category_id']);
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  _loadSeries() async {
    try {
      String url = '$_server/player_api.php?username=$_username&password=$_password&action=get_series';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _series = json.decode(response.body);
      }
    } catch (e) {
      print('Error loading series: $e');
    }
  }

  _filterSeries(String categoryId) {
    setState(() {
      _filteredSeries = _series.where((s) => s['category_id'] == categoryId).toList();
    });
  }

  _showSeasons(dynamic series) async {
    try {
      String url = '$_server/player_api.php?username=$_username&password=$_password&action=get_series_info&series_id=${series['series_id']}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeasonsScreen(seriesData: data, seriesName: series['name']),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
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
           ? Center(child: CircularProgressIndicator(color: Colors.orange))
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
                              CircleAvatar(radius: 25, backgroundImage: AssetImage('assets/avatar.png')),
                              SizedBox(width: 10),
                              Text('SERIES', style: TextStyle(color: Colors.orange, fontSize: 24, fontWeight: FontWeight.bold)),
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
                                    _filterSeries(_categories[index]['category_id']);
                                  }
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedCategory = index);
                                    _filterSeries(_categories[index]['category_id']);
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: selected? Colors.orange.withOpacity(0.3) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: selected? Colors.orange : Colors.white24, width: selected? 3 : 1),
                                    ),
                                    child: Text(
                                      _categories[index]['category_name'],
                                      style: TextStyle(color: selected? Colors.orange : Colors.white, fontSize: 16, fontWeight: selected? FontWeight.bold : FontWeight.normal),
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
                  // Series Grid
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.all(20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: _filteredSeries.length,
                      itemBuilder: (context, index) {
                        var series = _filteredSeries[index];
                        return Focus(
                          child: GestureDetector(
                            onTap: () => _showSeasons(series),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.orange, width: 2),
                                boxShadow: [BoxShadow(color: Colors.orange, blurRadius: 10)],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (series['cover']!= null && series['cover']!= '')
                                      Image.network(series['cover'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[900], child: Icon(Icons.tv, size: 60, color: Colors.white54)))
                                    else
                                      Container(color: Colors.grey[900], child: Icon(Icons.tv, size: 60, color: Colors.white54)),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(8),
                                        color: Colors.black.withOpacity(0.8),
                                        child: Text(
                                          series['name'],
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

// شاشة المواسم والحلقات
class SeasonsScreen extends StatefulWidget {
  final dynamic seriesData;
  final String seriesName;
  
  SeasonsScreen({required this.seriesData, required this.seriesName});
  
  @override
  _SeasonsScreenState createState() => _SeasonsScreenState();
}

class _SeasonsScreenState extends State<SeasonsScreen> {
  int _selectedSeason = 0;
  
  @override
  Widget build(BuildContext context) {
    var seasons = widget.seriesData['seasons']?? [];
    var episodes = widget.seriesData['episodes']?? {};
    String currentSeason = seasons.isNotEmpty? seasons[_selectedSeason].toString() : '1';
    var currentEpisodes = episodes[currentSeason]?? [];

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
                  Text(widget.seriesName, style: TextStyle(color: Colors.orange, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              height: 60,
              color: Colors.black.withOpacity(0.5),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: seasons.length,
                itemBuilder: (context, index) {
                  bool selected = _selectedSeason == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSeason = index),
                    child: Container(
                      width: 120,
                      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected? Colors.orange : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      child: Center(
                        child: Text('Season ${seasons[index]}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(20),
                itemCount: currentEpisodes.length,
                itemBuilder: (context, index) {
                  var episode = currentEpisodes[index];
                  return Focus(
                    child: GestureDetector(
                      onTap: () {
                        SharedPreferences.getInstance().then((prefs) {
                          String server = prefs.getString('server')?? '';
                          String user = prefs.getString('username')?? '';
                          String pass = prefs.getString('password')?? '';
                          String url = '$server/series/$user/$pass/${episode['id']}.${episode['container_extension']}';
                          Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayer(streamUrl: url, channelName: '${widget.seriesName} S$currentSeason E${episode['episode_num']}')));
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 15),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Text('E${episode['episode_num']}', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(episode['title']?? 'Episode ${episode['episode_num']}', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 5),
                                  Text('Season $currentSeason', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                ],
                              ),
                            ),
                            Icon(Icons.play_circle_filled, color: Colors.orange, size: 40),
                          ],
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
