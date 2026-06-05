import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'player.dart';

class SeriesScreen extends StatefulWidget { @override _SeriesScreenState createState() => _SeriesScreenState(); }
class _SeriesScreenState extends State<SeriesScreen> {
  List series = []; List cats = []; String sel = 'All'; bool loading = true;
  @override void initState() { super.initState(); _load(); }
  _load() async {
    final p = await SharedPreferences.getInstance();
    String s = (p.getString('server')?? '').replaceAll(RegExp(r'/$'), '');
    String u = p.getString('username')?? ''; String pw = p.getString('password')?? '';
    try {
      final c = await http.get(Uri.parse('$s/player_api.php?username=$u&password=$pw&action=get_series_categories')).timeout(Duration(seconds: 15));
      final se = await http.get(Uri.parse('$s/player_api.php?username=$u&password=$pw&action=get_series')).timeout(Duration(seconds: 20));
      if (c.statusCode == 200) cats = json.decode(c.body);
      if (se.statusCode == 200) series = json.decode(se.body);
    } catch(_) {}
    setState(() => loading = false);
  }
  @override Widget build(BuildContext context) {
    final f = sel == 'All'? series : series.where((e) => e['category_id'].toString() == sel).toList();
    return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.transparent, title: Text('SERIES')), body: loading? Center(child: CircularProgressIndicator(color: Colors.orange)) : f.isEmpty? Center(child: Text('لا يوجد مسلسلات', style: TextStyle(color: Colors.white70))) : Column(children: [
      Container(height: 50, child: ListView(scrollDirection: Axis.horizontal, children: [ActionChip(label: Text('الكل'), onPressed: () => setState(() => sel = 'All')),...cats.map((c) => Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: ActionChip(label: Text(c['category_name']), onPressed: () => setState(() => sel = c['category_id'].toString()))))])),
      Expanded(child: GridView.builder(padding: EdgeInsets.all(15), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, childAspectRatio: 0.7), itemCount: f.length, itemBuilder: (_, i) { final s = f[i]; return GestureDetector(onTap: () => _open(s), child: Column(children: [Expanded(child: s['cover']!= null? Image.network(s['cover'], fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.tv, color: Colors.white30)) : Icon(Icons.tv, color: Colors.white30)), Text(s['name'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 11))])); })),
    ]));
  }
  _open(s) async { final p = await SharedPreferences.getInstance(); String sv = p.getString('server')?? ''; String u = p.getString('username')?? ''; String pw = p.getString('password')?? ''; final r = await http.get(Uri.parse('$sv/player_api.php?username=$u&password=$pw&action=get_series_info&series_id=${s['series_id']}')); final d = json.decode(r.body); final eps = d['episodes']; showDialog(context: context, builder: (_) => AlertDialog(backgroundColor: Colors.black, title: Text(s['name'], style: TextStyle(color: Colors.white)), content: Container(width: 400, height: 400, child: ListView(children: eps.keys.map((se) => ExpansionTile(title: Text('الموسم $se', style: TextStyle(color: Colors.orange)), children: (eps[se] as List).map((e) => ListTile(title: Text(e['title'], style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); String url = '$sv/series/$u/$pw/${e['id']}.${e['container_extension']}'; Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(url: url, title: e['title']))); })).toList())).toList())))); }
}
