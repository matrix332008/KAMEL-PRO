import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'player.dart';

class LiveTV extends StatefulWidget {
  @override
  _LiveTVState createState() => _LiveTVState();
}

class _LiveTVState extends State<LiveTV> {
  List<dynamic> channels = [];
  List<dynamic> groups = [];
  String selectedGroup = 'All';
  bool _loading = true;
  int _selectedIndex = 0;
  String _channelNumber = '';
  final FocusNode _listFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _listFocusNode.requestFocus();
    _loadChannels();
  }

  @override
  void dispose() {
    _listFocusNode.dispose();
    super.dispose();
  }

  _loadChannels() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String loginType = prefs.getString('loginType')?? '';

    if (loginType == 'xtream') {
      String server = prefs.getString('server')?? '';
      String user = prefs.getString('username')?? '';
      String pass = prefs.getString('password')?? '';
      
      // جيب البوكات - Categories
      String catUrl = '$server/player_api.php?username=$user&password=$pass&action=get_live_categories';
      // جيب القنوات - Streams
      String url = '$server/player_api.php?username=$user&password=$pass&action=get_live_streams';

      try {
        final catResponse = await http.get(Uri.parse(catUrl)).timeout(Duration(seconds: 10));
        final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));
        
        if (response.statusCode == 200 && catResponse.statusCode == 200) {
          var allChannels = json.decode(response.body);
          var allGroups = json.decode(catResponse.body);
          
          // زيد رابط التشغيل لكل قناة
          for (var channel in allChannels) {
            int streamId = channel['stream_id'];
            channel['stream_url'] = '$server/live/$user/$pass/$streamId.m3u8';
          }
          
          setState(() {
            channels = allChannels;
            groups = [{'category_id': 'All', 'category_name': 'All Channels'}] + allGroups;
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
      } catch (e) {
        print('Error: $e');
        setState(() => _loading = false);
      }
    }
    // تو نزيد M3U بعدين
  }

  List<dynamic> get filteredChannels {
    if (selectedGroup == 'All') return channels;
    return channels.where((c) => c['category_id'] == selectedGroup).toList();
  }

  _playChannel(int index) {
    if (index < 0 || index >= filteredChannels.length) return;
    var channel = filteredChannels[index];
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlayerScreen(
        url: channel['stream_url']?? '',
        title: channel['name']?? '',
        channelList: filteredChannels,
        currentIndex: index,
      ),
    ));
  }

  _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() => _selectedIndex = (_selectedIndex + 1).clamp(0, filteredChannels.length - 1));
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() => _selectedIndex = (_selectedIndex - 1).clamp(0, filteredChannels.length - 1));
      } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
        _playChannel(_selectedIndex);
      } else if (event.logicalKey.keyLabel.length == 1 && int.tryParse(event.logicalKey.keyLabel)!= null) {
        setState(() {
          _channelNumber += event.logicalKey.keyLabel;
          if (_channelNumber.length >= 3) {
            int? channelNum = int.tryParse(_channelNumber);
            if (channelNum!= null && channelNum > 0 && channelNum <= filteredChannels.length) {
              _playChannel(channelNum - 1);
            }
            _channelNumber = '';
          }
        });
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) setState(() => _channelNumber = '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _listFocusNode,
      onKey: _handleKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _loading
           ? Center(child: CircularProgressIndicator(color: Colors.cyan))
            : Row(
                children: [
                  // البوكات - Groups
                  Container(
                    width: 250,
                    color: Colors.black.withOpacity(0.9),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          child: Text('BOUQUETS', style: TextStyle(color: Colors.cyan, fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: groups.length,
                            itemBuilder: (context, index) {
                              bool selected = groups[index]['category_id'] == selectedGroup;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  selectedGroup = groups[index]['category_id'];
                                  _selectedIndex = 0;
                                }),
                                child: Container(
                                  padding: EdgeInsets.all(15),
                                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: selected? Colors.cyan.withOpacity(0.3) : Colors.transparent,
                                    border: Border.all(color: selected? Colors.cyan : Colors.transparent, width: 2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    groups[index]['category_name'],
                                    style: TextStyle(color: selected? Colors.cyan : Colors.white, fontWeight: selected? FontWeight.bold : FontWeight.normal, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // القنوات - Channels
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(image: DecorationImage(image: AssetImage('assets/background.jpeg'), fit: BoxFit.cover)),
                      child: Column(
                        children: [
                          if (_channelNumber.isNotEmpty)
                            Container(
                              padding: EdgeInsets.all(20),
                              margin: EdgeInsets.only(top: 30),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
                              child: Text(_channelNumber, style: TextStyle(color: Colors.cyan, fontSize: 60, fontWeight: FontWeight.bold)),
                            ),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.all(20),
                              itemCount: filteredChannels.length,
                              itemBuilder: (context, index) {
                                bool selected = index == _selectedIndex;
                                var channel = filteredChannels[index];
                                return GestureDetector(
                                  onTap: () => _playChannel(index),
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    margin: EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: selected? Colors.cyan.withOpacity(0.3) : Colors.black.withOpacity(0.6),
                                      border: Border.all(color: selected? Colors.cyan : Colors.transparent, width: 3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          child: Text('${index + 1}.', style: TextStyle(color: Colors.cyan, fontSize: 18, fontWeight: FontWeight.bold)),
                                        ),
                                        if (channel['stream_icon']!= null && channel['stream_icon']!= '')
                                          Image.network(channel['stream_icon'], width: 40, height: 40, errorBuilder: (c, e, s) => Icon(Icons.tv, color: Colors.white54)),
                                        if (channel['stream_icon'] == null || channel['stream_icon'] == '')
                                          Icon(Icons.tv, color: Colors.white54, size: 40),
                                        SizedBox(width: 15),
                                        Expanded(
                                          child: Text(
                                            channel['name']?? '',
                                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: selected? FontWeight.bold : FontWeight.normal),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
