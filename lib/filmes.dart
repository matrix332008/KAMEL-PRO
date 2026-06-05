import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'player.dart';

class FilmesScreen extends StatefulWidget { @override _FilmesScreenState createState() => _FilmesScreenState(); }
class _FilmesScreenState extends State<FilmesScreen> {
  List movies = []; List cats = []; String sel = 'All'; bool loading = true;
  @override void initState() { super.initState(); _load(); }
  _load() async {
    final p = await SharedPreferences.getInstance();
    String s = (p.getString('server')?? '').replaceAll(RegExp(r'/$'), '');
    String u = p.getString('username')?? ''; String pw = p.getString('password')?? '';
    try {
      final c = await http.get(Uri.parse('$s/player_api.php?username=$u&password=$pw&action=get_vod_categories')).timeout(Duration(seconds: 15));
      final m = await http.get(Uri.parse('$s/player_api.php?username=$u&password=$pw&action=get_vod_streams')).timeout(Duration(seconds: 20));
      if (c.statusCode == 200) cats = json.decode(c.body);
      if (m.statusCode == 200) movies = json.decode(m.body);
    } catch(_) {}
    setState(() => loading = false);
  }
  @override Widget build(BuildContext context) {
    final f = sel == 'All'? movies : movies.where((e) => e['category_id'].toString() == sel).toList();
    return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.transparent, title: Text('FILMES'), actions: [Padding(padding: EdgeInsets.all(16), child: Text('${f.length} فيلم'))]), body: loading? Center(child: CircularProgressIndicator(color: Colors.red)) : f.isEmpty? Center(child: Text('لا يوجد أفلام', style: TextStyle(color: Colors.white70, fontSize: 22))) : Column(children: [
      Container(height: 50, child: ListView(scrollDirection: Axis.horizontal, children: [Chip(label: Text('الكل'), onDeleted: () => setState(() => sel = 'All')),...cats.map((c) => Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: ActionChip(label: Text(c['category_name']), onPressed: () => setState(() => sel = c['category_id'].toString()))))])),
      Expanded(child: GridView.builder(padding: EdgeInsets.all(15), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, childAspectRatio: 0.7), itemCount: f.length, itemBuilder: (_, i) { final m = f[i]; return GestureDetector(onTap: () async { final p = await SharedPreferences.getInstance(); String s = p.getString('server')?? ''; String u = p.getString('username')?? ''; String pw = p.getString('password')?? ''; String url = '$s/movie/$u/$pw/${m['stream_id']}.${m['container_extension']}'; Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(url: url, title: m['name']))); }, child: Column(children: [Expanded(child: m['stream_icon']!= null? Image.network(m['stream_icon'], fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.movie, color: Colors.white30, size: 50)) : Icon(Icons.movie, color: Colors.white30, size: 50)), Text(m['name'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 11), textAlign: TextAlign.center)])); })),
    ]));
  }
}
