import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class EPGScreen extends StatefulWidget {
  @override
  _EPGScreenState createState() => _EPGScreenState();
}

class _EPGScreenState extends State<EPGScreen> {
  List<dynamic> _channels = [];
  Map<String, List<dynamic>> _epgData = {};
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  String _server = '';
  String _username = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    _loadEPG();
  }

  _loadEPG() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _server = prefs.getString('server')?? '';
    _username = prefs.getString('username')?? '';
    _password = prefs.getString('password')?? '';

    try {
      // Load channels
      String channelsUrl = '$_server/player_api.php?username=$_username&password=$_password&action=get_live_streams';
      final channelsResponse = await http.get(Uri.parse(channelsUrl));
      if (channelsResponse.statusCode == 200) {
        _channels = json.decode(channelsResponse.body).take(20).toList(); // اول 20 قناة
      }

      // Load EPG for each channel
      for (var channel in _channels) {
        String epgUrl = '$_server/player_api.php?username=$_username&password=$_password&action=get_short_epg&stream_id=${channel['stream_id']}&limit=10';
        final epgResponse = await http.get(Uri.parse(epgUrl));
        if (epgResponse.statusCode == 200) {
          var data = json.decode(epgResponse.body);
          if (data['epg_listings']!= null) {
            _epgData[channel['stream_id'].toString()] = data['epg_listings'];
          }
        }
      }
    } catch (e) {
      print('Error loading EPG: $e');
    }
    setState(() => _loading = false);
  }

  List<DateTime> _getWeekDays() {
    return List.generate(7, (i) => DateTime.now().add(Duration(days: i)));
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
            // Header
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.black.withOpacity(0.7),
              child: Row(
                children: [
                  CircleAvatar(radius: 25, backgroundImage: AssetImage('assets/avatar.png')),
                  SizedBox(width: 20),
                  Text(
                    'EPG - TV GUIDE',
                    style: TextStyle(color: Colors.red, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            // Days Selector
            Container(
              height: 60,
              color: Colors.black.withOpacity(0.5),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, index) {
                  DateTime date = _getWeekDays()[index];
                  bool selected = DateUtils.isSameDay(date, _selectedDate);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = date),
                    child: Container(
                      width: 100,
                      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected? Colors.red : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEE').format(date),
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            Text(
                              DateFormat('dd').format(date),
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // EPG Grid
            Expanded(
              child: _loading
                 ? Center(child: CircularProgressIndicator(color: Colors.red))
                  : ListView.builder(
                      itemCount: _channels.length,
                      itemBuilder: (context, index) {
                        var channel = _channels[index];
                        var programs = _epgData[channel['stream_id'].toString()]?? [];
                        return Container(
                          height: 80,
                          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 150,
                                padding: EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    if (channel['stream_icon']!= null)
                                      Image.network(channel['stream_icon'], width: 40, height: 40)
                                    else
                                      Icon(Icons.tv, color: Colors.white54),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        channel['name'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: programs.length,
                                  itemBuilder: (context, progIndex) {
                                    var prog = programs[progIndex];
                                    return Container(
                                      width: 200,
                                      margin: EdgeInsets.all(5),
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            prog['title']?? 'No Title',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '${prog['start']?.substring(11, 16)?? ''} - ${prog['end']?.substring(11, 16)?? ''}',
                                            style: TextStyle(color: Colors.white70, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
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
