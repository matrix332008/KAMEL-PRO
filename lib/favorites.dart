import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'player.dart';
import 'lang.dart';

class Fav {
  static Future<List> get(String type) async {
    final p = await SharedPreferences.getInstance();
    return json.decode(p.getString('fav_$type')?? '[]');
  }
  static Future<bool> toggle(String type, Map item) async {
    final p = await SharedPreferences.getInstance();
    List list = await get(type);
    String id = item['id'].toString();
    int i = list.indexWhere((e) => e['id'].toString() == id);
    bool added = i < 0;
    if (i >= 0) list.removeAt(i); else list.add(item);
    await p.setString('fav_$type', json.encode(list));
    return added;
  }
  static Future<bool> isFav(String type, String id) async {
    List list = await get(type);
    return list.any((e) => e['id'].toString() == id);
  }
}

class FavoritesScreen extends StatefulWidget {
  @override _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List live = [], movies = [], series = [];

  @override void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); _load(); }

  _load() async {
    live = await Fav.get('live');
    movies = await Fav.get('movies');
    series = await Fav.get('series');
    setState(() {});
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(Lang.get('fav'), style: TextStyle(color: Colors.red)),
        bottom: TabBar(controller: _tab, indicatorColor: Colors.red, tabs: [
          Tab(text: Lang.get('live')),
          Tab(text: Lang.get('movies')),
          Tab(text: Lang.get('series')),
        ]),
      ),
      body: TabBarView(controller: _tab, children: [
        _buildList(live, 'live'),
        _buildList(movies, 'movies'),
        _buildList(series, 'series'),
      ]),
    );
  }

  Widget _buildList(List items, String type) {
    if (items.isEmpty) return Center(child: Text('No favorites', style: TextStyle(color: Colors.white70)));
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.8, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        var it = items[i];
        return GestureDetector(
          onTap: () async {
            final p = await SharedPreferences.getInstance();
            // تم التعديل: نستعمل server_url
            String s = p.getString('server_url')?? p.getString('server')?? '';
            String u = p.getString('username')??'';
            String pw = p.getString('password')??'';
            String url = type=='live'? '$s/live/$u/$pw/${it['id']}.ts' : '$s/movie/$u/$pw/${it['id']}.${it['ext']??'mp4'}';
            Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(url: url, title: it['name'], logo: it['logo'])));
          },
          onLongPress: () async { await Fav.toggle(type, it); _load(); },
          child: Container(
            decoration: BoxDecoration(color: Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(12)), child: it['logo']!=null? Image.network(it['logo'], fit: BoxFit.cover, width: double.infinity, errorBuilder: (_,__,___)=>Icon(Icons.tv, color: Colors.white24)) : Icon(Icons.tv, color: Colors.white24))),
              Padding(padding: EdgeInsets.all(6), child: Text(it['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 12))),
            ]),
          ),
        );
      },
    );
  }
}
