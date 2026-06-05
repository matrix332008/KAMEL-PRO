import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'player.dart';

class LiveTV extends StatefulWidget { @override _LiveTVState createState() => _LiveTVState(); }
class _LiveTVState extends State<LiveTV> {
  List channels = []; List groups = []; String sel = 'All'; bool loading = true;
  @override void initState() { super.initState(); _load(); }
  _load() async {
    final p = await SharedPreferences.getInstance();
    String s = (p.getString('server')?? '').replaceAll(RegExp(r'/$'), '');
    String u = p.getString('username')?? ''; String pw = p.getString('password')?? '';
    try {
      final c = await http.get(Uri.parse('$s/player_api.php?username=$u&password=$pw&action=get_live_categories')).timeout(Duration(seconds: 10));
      final ch = await http.get(Uri.parse('$s/player_api.php?username=$u&password=$pw&action=get_live_streams')).timeout(Duration(seconds: 15));
      if (ch.statusCode == 200) channels = json.decode(ch.body);
      if (c.statusCode == 200) groups = [{'category_id':'All','category_name':'الكل'}] + List.from(json.decode(c.body));
      else groups = [{'category_id':'All','category_name':'الكل'}];
    } catch(_) { groups = [{'category_id':'All','category_name':'الكل'}]; }
    setState(() => loading = false);
  }
  @override Widget build(BuildContext context) {
    final f = sel == 'All'? channels : channels.where((e) => e['category_id'].toString() == sel).toList();
    return Scaffold(backgroundColor: Colors.black, body: loading? Center(child: CircularProgressIndicator(color: Colors.cyan)) : Row(children: [
      Container(width: 250, color: Colors.black87, child: Column(children: [
        Padding(padding: EdgeInsets.all(15), child: Row(children: [IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)), Text('الباقات', style: TextStyle(color: Colors.cyan, fontSize: 20))])),
        Expanded(child: ListView.builder(itemCount: groups.length, itemBuilder: (_, i) { final g = groups[i]; return ListTile(selected: g['category_id'].toString() == sel, title: Text(g['category_name'], style: TextStyle(color: Colors.white)), onTap: () => setState(() => sel = g['category_id'].toString())); })),
      ])),
      Expanded(child: GridView.builder(padding: EdgeInsets.all(15), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, childAspectRatio: 1.5, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: f.length, itemBuilder: (_, i) { final ch = f[i]; return GestureDetector(onTap: () async { final p = await SharedPreferences.getInstance(); String s = p.getString('server')?? ''; String u = p.getString('username')?? ''; String pw = p.getString('password')?? ''; String url = '$s/live/$u/$pw/${ch['stream_id']}.ts'; Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(url: url, title: ch['name'], channelList: f.map((e) => {'name': e['name'], 'url': '$s/live/$u/$pw/${e['stream_id']}.ts'}).toList(), currentIndex: i))); }, child: Container(alignment: Alignment.center, decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)), child: Text(ch['name'], textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12), maxLines: 2))); })),
    ]));
  }
}
