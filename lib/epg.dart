import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class EPGScreen extends StatefulWidget {
  @override
  _EPGScreenState createState() => _EPGScreenState();
}

class _EPGScreenState extends State<EPGScreen> {
  List channels = [];
  List epg = [];
  int selectedChannel = 0;
  bool loading = true;
  String server = '';
  String user = '';
  String pass = '';

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    final p = await SharedPreferences.getInstance();
    server = (p.getString('server')?? '').replaceAll(RegExp(r'/$'), '');
    user = p.getString('username')?? '';
    pass = p.getString('password')?? '';

    try {
      final res = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_live_streams')).timeout(Duration(seconds: 15));
      if (res.statusCode == 200) {
        channels = json.decode(res.body);
        if (channels.isNotEmpty) await _loadEPG(channels[0]['stream_id'].toString());
      }
    } catch (e) {}
    setState(() => loading = false);
  }

  Future<void> _loadEPG(String streamId) async {
    setState(() => epg = []);
    try {
      final res = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_short_epg&stream_id=$streamId&limit=50')).timeout(Duration(seconds: 10));
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        if (data['epg_listings']!= null) {
          epg = data['epg_listings'];
        }
      }
    } catch (e) {}
    setState(() {});
  }

  String _formatTime(String start, String end) {
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      return '${DateFormat('HH:mm').format(s)} - ${DateFormat('HH:mm').format(e)}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpeg', fit: BoxFit.fill),
          Container(color: Colors.black.withOpacity(0.7)),
          loading
             ? Center(child: CircularProgressIndicator(color: Colors.red))
              : Row(
                  children: [
                    // القنوات يسار
                    Container(
                      width: 300,
                      color: Colors.black87,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                                Text('EPG', style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: channels.length,
                              itemBuilder: (_, i) {
                                final ch = channels[i];
                                final active = i == selectedChannel;
                                return Focus(
                                  autofocus: i == 0,
                                  onKeyEvent: (node, event) {
                                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
                                      setState(() => selectedChannel = i);
                                      _loadEPG(ch['stream_id'].toString());
                                      return KeyEventResult.handled;
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: Builder(builder: (ctx) {
                                    final hasFocus = Focus.of(ctx).hasFocus;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() => selectedChannel = i);
                                        _loadEPG(ch['stream_id'].toString());
                                      },
                                      child: Container(
                                        color: hasFocus? Colors.red.withOpacity(0.3) : (active? Colors.red.withOpacity(0.2) : Colors.transparent),
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        child: Row(
                                          children: [
                                            if (ch['stream_icon']!= null && ch['stream_icon'].toString().isNotEmpty)
                                              Image.network(ch['stream_icon'], width: 40, height: 40, errorBuilder: (_, __, ___) => Icon(Icons.tv, color: Colors.white30))
                                            else
                                              Icon(Icons.tv, color: Colors.white30),
                                            SizedBox(width: 10),
                                            Expanded(child: Text(ch['name']?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: active || hasFocus? Colors.redAccent : Colors.white))),
                                          ],
                                        ),
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
                    // البرامج يمين
                    Expanded(
                      child: epg.isEmpty
                         ? Center(child: Text('لا توجد بيانات', style: TextStyle(color: Colors.white70, fontSize: 18)))
                          : ListView.builder(
                              padding: EdgeInsets.all(20),
                              itemCount: epg.length,
                              itemBuilder: (_, i) {
                                final prog = epg[i];
                                final now = DateTime.now();
                                final start = DateTime.tryParse(prog['start']?? '');
                                final end = DateTime.tryParse(prog['end']?? '');
                                final isNow = start!= null && end!= null && now.isAfter(start) && now.isBefore(end);

                                return Focus(
                                  autofocus: i == 0,
                                  child: Builder(builder: (ctx) {
                                    final hasFocus = Focus.of(ctx).hasFocus;
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 12),
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isNow? Colors.red.withOpacity(0.2) : Colors.black.withOpacity(0.5),
                                        border: Border.all(color: hasFocus? Colors.redAccent : (isNow? Colors.red : Colors.white24), width: hasFocus? 2 : 1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(_formatTime(prog['start'], prog['end']), style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                                              if (isNow)...[
                                                SizedBox(width: 10),
                                                Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: Text('الآن', style: TextStyle(color: Colors.white, fontSize: 12))),
                                              ]
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Text(prog['title']?? '', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                          if (prog['description']!= null && prog['description'].toString().isNotEmpty)...[
                                            SizedBox(height: 6),
                                            Text(prog['description'], maxLines: hasFocus? 5 : 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white70, fontSize: 14)),
                                          ],
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
        ],
      ),
    );
  }
}
