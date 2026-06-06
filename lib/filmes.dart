import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    String server = (p.getString('server')?? '').replaceAll(RegExp(r'/$'), '');
    String user = p.getString('username')?? '';
    String pass = p.getString('password')?? '';
    try {
      final cRes = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_vod_categories')).timeout(Duration(seconds: 15));
      final mRes = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_vod_streams')).timeout(Duration(seconds: 20));
      if (cRes.statusCode == 200) cats = json.decode(cRes.body);
      if (mRes.statusCode == 200) movies = json.decode(mRes.body);
    } catch (e) {}
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = sel == 'All'? movies : movies.where((m) => m['category_id'].toString() == sel).toList();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('FILMES'),
        actions: [Padding(padding: EdgeInsets.all(16), child: Text('${filtered.length} فيلم', style: TextStyle(color: Colors.white70)))],
      ),
      body: loading
         ? Center(child: CircularProgressIndicator(color: Colors.red))
          : Column(
              children: [
                Container(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _buildChip('All', 'الكل'),
                     ...cats.map((c) => _buildChip(c['category_id'].toString(), c['category_name'])),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(14),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 0.68,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final m = filtered[i];
                      return Focus(
                        autofocus: i == 0,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
                            _play(m);
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Builder(
                          builder: (ctx) {
                            final hasFocus = Focus.of(ctx).hasFocus;
                            return GestureDetector(
                              onTap: () => _play(m),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: hasFocus? Colors.red : Colors.transparent, width: 3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: m['stream_icon']!= null && m['stream_icon'].toString().isNotEmpty
                                           ? Image.network(m['stream_icon'], fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Container(color: Colors.grey[900], child: Icon(Icons.movie, size: 50, color: Colors.white30)))
                                            : Container(color: Colors.grey[900], child: Icon(Icons.movie, size: 50, color: Colors.white30)),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(m['name']?? '', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChip(String id, String name) {
    final selected = sel == id;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Focus(
        child: Builder(
          builder: (ctx) {
            final hasFocus = Focus.of(ctx).hasFocus;
            return ChoiceChip(
              label: Text(name, style: TextStyle(color: selected? Colors.black : Colors.white)),
              selected: selected,
              selectedColor: Colors.red,
              backgroundColor: hasFocus? Colors.white24 : Colors.grey[800],
              onSelected: (_) => setState(() => sel = id),
            );
          },
        ),
      ),
    );
  }

  void _play(m) async {
    final p = await SharedPreferences.getInstance();
    String server = p.getString('server')?? '';
    String user = p.getString('username')?? '';
    String pass = p.getString('password')?? '';
    String url = '$server/movie/$user/$pass/${m['stream_id']}.${m['container_extension']}';
    Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(url: url, title: m['name'], logo: m['stream_icon'])));
  }
}
