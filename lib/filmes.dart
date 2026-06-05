import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'player.dart';

class FilmesScreen extends StatefulWidget {
  @override
  _FilmesScreenState createState() => _FilmesScreenState();
}

class _FilmesScreenState extends State<FilmesScreen> {
  List movies = [];
  List cats = [];
  String sel = 'All';
  bool loading = true;
  String server = '', user = '', pass = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    final p = await SharedPreferences.getInstance();
    server = (p.getString('server')?? '').replaceAll(RegExp(r'/$'), '');
    user = p.getString('username')?? '';
    pass = p.getString('password')?? '';

    try {
      final catRes = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_vod_categories')).timeout(Duration(seconds: 10));
      final movRes = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_vod_streams')).timeout(Duration(seconds: 15));

      if (catRes.statusCode == 200 && movRes.statusCode == 200) {
        cats = [{'category_id': 'All', 'category_name': 'الكل'}] + json.decode(catRes.body);
        movies = json.decode(movRes.body);

        for (var m in movies) {
          final ext = m['container_extension']?? 'mp4';
          m['stream_url'] = '$server/movie/$user/$pass/${m['stream_id']}.$ext';
        }
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  List get filtered => sel == 'All'? movies : movies.where((m) => m['category_id'] == sel).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: loading
         ? Center(child: CircularProgressIndicator(color: Colors.red))
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(icon: Icon(Icons.arrow_back, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
                      SizedBox(width: 20),
                      Text('FILMES', style: TextStyle(color: Colors.red, fontSize: 28, fontWeight: FontWeight.bold)),
                      Spacer(),
                      Text('${filtered.length} فيلم', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 220,
                        color: Colors.black.withOpacity(0.8),
                        child: ListView.builder(
                          itemCount: cats.length,
                          itemBuilder: (_, i) {
                            final c = cats[i];
                            final active = c['category_id'] == sel;
                            return GestureDetector(
                              onTap: () => setState(() => sel = c['category_id']),
                              child: Container(
                                padding: EdgeInsets.all(15),
                                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: active? Colors.red.withOpacity(0.3) : Colors.transparent,
                                  border: Border(left: BorderSide(color: active? Colors.red : Colors.transparent, width: 4)),
                                ),
                                child: Text(c['category_name'], style: TextStyle(color: active? Colors.red : Colors.white, fontSize: 15), overflow: TextOverflow.ellipsis),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: EdgeInsets.all(15),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, childAspectRatio: 0.65, crossAxisSpacing: 12, mainAxisSpacing: 12),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final m = filtered[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(url: m['stream_url'], title: m['name']))),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[900]),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: m['stream_icon']!= null && m['stream_icon']!= ''
                                           ? Image.network(m['stream_icon'], fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.movie, size: 50, color: Colors.white30)))
                                            : Center(child: Icon(Icons.movie, size: 50, color: Colors.white30)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(m['name']?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
