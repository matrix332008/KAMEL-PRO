import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'player.dart';

class SeriesScreen extends StatefulWidget {
  @override
  _SeriesScreenState createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  List series = [];
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
      final cRes = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_series_categories')).timeout(Duration(seconds: 15));
      final sRes = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_series')).timeout(Duration(seconds: 20));
      if (cRes.statusCode == 200) cats = json.decode(cRes.body);
      if (sRes.statusCode == 200) series = json.decode(sRes.body);
    } catch (e) {}
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = sel == 'All'? series : series.where((s) => s['category_id'].toString() == sel).toList();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text('SERIES')),
      body: loading
        ? Center(child: CircularProgressIndicator(color: Colors.orange))
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
                      final s = filtered[i];
                      return Focus(
                        autofocus: i == 0,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
                            _openSeries(s);
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Builder(
                          builder: (ctx) {
                            final hasFocus = Focus.of(ctx).hasFocus;
                            return GestureDetector(
                              onTap: () => _openSeries(s),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: hasFocus? Colors.orange : Colors.transparent, width: 3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: s['cover']!= null && s['cover'].toString().isNotEmpty
                                          ? Image.network(s['cover'], fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Container(color: Colors.grey[900], child: Icon(Icons.tv, size: 50, color: Colors.white30)))
                                            : Container(color: Colors.grey[900], child: Icon(Icons.tv, size: 50, color: Colors.white30)),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(s['name']?? '', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11)),
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
              selectedColor: Colors.orange,
              backgroundColor: hasFocus? Colors.white24 : Colors.grey[800],
              onSelected: (_) => setState(() => sel = id),
            );
          },
        ),
      ),
    );
  }

  void _openSeries(s) async {
    final p = await SharedPreferences.getInstance();
    String server = p.getString('server')?? '';
    String user = p.getString('username')?? '';
    String pass = p.getString('password')?? '';
    final res = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_series_info&series_id=${s['series_id']}'));
    final data = json.decode(res.body);
    final episodes = data['episodes'];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF111111),
        title: Text(s['name'], style: TextStyle(color: Colors.white)),
        content: Container(
          width: 500,
          height: 450,
          child: ListView(
            children: episodes.keys.map<Widget>((season) {
              return ExpansionTile(
                title: Text('الموسم $season', style: TextStyle(color: Colors.orange)),
                children: (episodes[season] as List).map((ep) {
                  return ListTile(
                    title: Text(ep['title'], style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      String url = '$server/series/$user/$pass/${ep['id']}.${ep['container_extension']}';
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(url: url, title: ep['title'], logo: s['cover'])));
                    },
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
