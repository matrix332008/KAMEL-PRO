import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:xml/xml.dart';

class EPGScreen extends StatefulWidget {
  @override
  _EPGScreenState createState() => _EPGScreenState();
}

class _EPGScreenState extends State<EPGScreen> {
  List<dynamic> channels = [];
  Map<String, List<Map<String, dynamic>>> epgData = {};
  int selectedChannel = 0;
  int selectedProgram = 0;
  bool loading = true;
  final ScrollController _channelScroll = ScrollController();
  final ScrollController _programScroll = ScrollController();
  final FocusNode _channelFocus = FocusNode();
  final FocusNode _programFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadEPG();
    WidgetsBinding.instance.addPostFrameCallback((_) => _channelFocus.requestFocus());
  }

  _loadEPG() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String server = prefs.getString('server')?? '';
    String user = prefs.getString('username')?? '';
    String pass = prefs.getString('password')?? '';

    try {
      // 1. جيب القنوات
      final channelsRes = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_live_streams'));
      if (channelsRes.statusCode == 200) {
        channels = json.decode(channelsRes.body);
        channels = channels.take(50).toList(); // أول 50 قناة باش ما يثقلش

        // 2. جيب EPG
        final epgRes = await http.get(Uri.parse('$server/xmltv.php?username=$user&password=$pass')).timeout(Duration(seconds: 15));
        if (epgRes.statusCode == 200) {
          final document = XmlDocument.parse(epgRes.body);
          final programmes = document.findAllElements('programme');

          for (var prog in programmes) {
            String channelId = prog.getAttribute('channel')?? '';
            String start = prog.getAttribute('start')?? '';
            String stop = prog.getAttribute('stop')?? '';
            String title = prog.findElements('title').first.text;
            String desc = prog.findElements('desc').isNotEmpty? prog.findElements('desc').first.text : '';

            if (!epgData.containsKey(channelId)) epgData[channelId] = [];
            epgData[channelId]!.add({
              'title': title,
              'desc': desc,
              'start': _parseTime(start),
              'stop': _parseTime(stop),
            });
          }
        }
      }
    } catch (e) {
      print('EPG Error: $e');
    }
    setState(() => loading = false);
  }

  String _parseTime(String t) {
    try {
      String time = t.substring(8, 12);
      return '${time.substring(0,2)}:${time.substring(2,4)}';
    } catch (e) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpeg', fit: BoxFit.fill),
          loading
             ? Center(child: CircularProgressIndicator(color: Colors.cyan))
              : Row(
                  children: [
                    // القنوات على اليسار
                    Container(
                      width: 300,
                      color: Colors.black.withOpacity(0.7),
                      child: Focus(
                        focusNode: _channelFocus,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent) {
                            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                              setState(() { if (selectedChannel < channels.length - 1) selectedChannel++; });
                              _channelScroll.animateTo(selectedChannel * 80.0, duration: Duration(milliseconds: 200), curve: Curves.ease);
                              return KeyEventResult.handled;
                            }
                            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                              setState(() { if (selectedChannel > 0) selectedChannel--; });
                              _channelScroll.animateTo(selectedChannel * 80.0, duration: Duration(milliseconds: 200), curve: Curves.ease);
                              return KeyEventResult.handled;
                            }
                            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                              _programFocus.requestFocus();
                              return KeyEventResult.handled;
                            }
                          }
                          return KeyEventResult.ignored;
                        },
                        child: ListView.builder(
                          controller: _channelScroll,
                          itemCount: channels.length,
                          itemBuilder: (context, index) {
                            bool focused = index == selectedChannel && _channelFocus.hasFocus;
                            return Container(
                              height: 80,
                              margin: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: focused? Colors.cyan.withOpacity(0.3) : Colors.transparent,
                                border: Border.all(color: focused? Colors.cyan : Colors.transparent, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 10),
                                  Image.network(channels[index]['stream_icon']?? '', width: 50, height: 50, errorBuilder: (_, __, ___) => Icon(Icons.tv, color: Colors.white)),
                                  SizedBox(width: 10),
                                  Expanded(child: Text(channels[index]['name']?? '', style: TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // البرامج على اليمين
                    Expanded(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Focus(
                          focusNode: _programFocus,
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                _channelFocus.requestFocus();
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: _buildPrograms(),
                        ),
                      ),
                    ),
                  ],
                ),
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrograms() {
    if (channels.isEmpty) return Center(child: Text('No channels', style: TextStyle(color: Colors.white)));
    String channelId = channels[selectedChannel]['epg_channel_id']?? channels[selectedChannel]['stream_id'].toString();
    List<Map<String, dynamic>> programs = epgData[channelId]?? [];

    if (programs.isEmpty) {
      return Center(child: Text('No EPG data', style: TextStyle(color: Colors.white70, fontSize: 20)));
    }

    return ListView.builder(
      controller: _programScroll,
      padding: EdgeInsets.all(20),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        var prog = programs[index];
        bool isNow = index == 0; // نبسطوها
        return Container(
          margin: EdgeInsets.only(bottom: 15),
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isNow? Colors.cyan.withOpacity(0.2) : Colors.black.withOpacity(0.3),
            border: Border.all(color: isNow? Colors.cyan : Colors.white24),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${prog['start']} - ${prog['stop']}', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  if (isNow)...[SizedBox(width: 10), Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)), child: Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 12)))],
                ],
              ),
              SizedBox(height: 8),
              Text(prog['title'], style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              if (prog['desc'].isNotEmpty)...[SizedBox(height: 5), Text(prog['desc'], style: TextStyle(color: Colors.white70, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)],
            ],
          ),
        );
      },
    );
  }
}
