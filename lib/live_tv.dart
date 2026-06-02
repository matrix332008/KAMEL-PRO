import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'player.dart';

class LiveTV extends StatefulWidget {
  @override
  _LiveTVState createState() => _LiveTVState();
}

class _LiveTVState extends State<LiveTV> {
  List<dynamic> _categories = [];
  List<dynamic> _channels = [];
  List<dynamic> _filteredChannels = [];
  int _selectedCategory = 0;
  int _selectedChannel = 0;
  bool _loading = true;
  String _server = '';
  String _username = '';
  String _password = '';

  final ScrollController _catController = ScrollController();
  final ScrollController _chanController = ScrollController();

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
    await _loadChannels();
    setState(() => _loading = false);
  }

  _loadCategories() async {
    try {
      String url = '$_server/player_api.php?username=$_username&password=$_password&action=get_live_categories';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _categories = json.decode(response.body);
        if (_categories.isNotEmpty) {
          _filterChannels(_categories[0]['category_id']);
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  _loadChannels() async {
    try {
      String url = '$_server/player_api.php?username=$_username&password=$_password&action=get_live_streams';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _channels = json.decode(response.body);
      }
    } catch (e) {
      print('Error loading channels: $e');
    }
  }

  _filterChannels(String categoryId) {
    setState(() {
      _filteredChannels = _channels.where((ch) => ch['category_id'] == categoryId).toList();
      _selectedChannel = 0;
    });
  }

  _playChannel(dynamic channel) {
    String streamUrl = '$_server/live/$_username/$_password/${channel['stream_id']}.m3u8';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayer(streamUrl: streamUrl, channelName: channel['name']),
      ),
    );
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
           ? Center(child: CircularProgressIndicator(color: Colors.cyan))
            : Row(
                children: [
                  // Categories Sidebar
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
                                'LIVE TV',
                                style: TextStyle(
                                  color: Colors.cyan,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: _catController,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              bool selected = _selectedCategory == index;
                              return Focus(
                                onFocusChange: (hasFocus) {
                                  if (hasFocus) {
                                    setState(() => _selectedCategory = index);
                                    _filterChannels(_categories[index]['category_id']);
                                  }
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedCategory = index);
                                    _filterChannels(_categories[index]['category_id']);
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: selected? Colors.cyan.withOpacity(0.3) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: selected? Colors.cyan : Colors.white24,
                                        width: selected? 3 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      _categories[index]['category_name'],
                                      style: TextStyle(
                                        color: selected? Colors.cyan : Colors.white,
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
                  // Channels Grid
                  Expanded(
                    child: GridView.builder(
                      controller: _chanController,
                      padding: EdgeInsets.all(20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: _filteredChannels.length,
                      itemBuilder: (context, index) {
                        bool selected = _selectedChannel == index;
                        var channel = _filteredChannels[index];
                        return Focus(
                          onFocusChange: (hasFocus) {
                            if (hasFocus) setState(() => _selectedChannel = index);
                          },
                          child: GestureDetector(
                            onTap: () => _playChannel(channel),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: selected? Colors.cyan : Colors.white24,
                                  width: selected? 4 : 2,
                                ),
                                boxShadow: selected
                                   ? [BoxShadow(color: Colors.cyan, blurRadius: 20)]
                                    : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (channel['stream_icon']!= null && channel['stream_icon']!= '')
                                    Image.network(
                                      channel['stream_icon'],
                                      height: 60,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.tv, size: 60, color: Colors.white54),
                                    )
                                  else
                                    Icon(Icons.tv, size: 60, color: Colors.white54),
                                  SizedBox(height: 10),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      channel['name'],
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: selected? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
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
