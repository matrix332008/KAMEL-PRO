import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'player.dart';
import 'lang.dart'; // <-- جديد

class SeriesScreen extends StatefulWidget {
  @override
  _SeriesScreenState createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  List series = [];
  List cats = [];
  String sel = 'all'; // <-- بدلناها
  bool loading = true;
  String _search = ''; // <-- جديد
  final _searchController = TextEditingController(); // <-- جديد

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
    var filtered = sel == 'all'? series : series.where((s) => s['category_id'].toString() == sel).toList();
    // فلترة البحث
    if (_search.isNotEmpty) {
      filtered = filtered.where((s) => (s['name']?? '').toString().toLowerCase().contains(_search.toLowerCase())).toList();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(Lang.get('series').toUpperCase())),
      body: loading
? Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                // --- SEARCH BAR جديد ---
                Container(
                  height: 48,
                  margin: EdgeInsets.fromLTRB(14, 0, 14, 8),
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Focus(
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
                              FocusScope.of(context).focusInDirection(TraversalDirection.down);
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _search = v),
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: Lang.get('search_series'), // ← تبدل
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      if (_search.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear, color: Colors.white54, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        ),
                    ],
                  ),
                ),
                Container(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _buildChip('all', Lang.get('all')), // <-- هنا
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
    String server = (p.getString('server')?? '').replaceAll(RegExp(r'/$'), '');
    String user = p.getString('username')?? '';
    String pass = p.getString('password')?? '';
    final res = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_series_info&series_id=${s['series_id']}'));
    final data = json.decode(res.body);

    Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesDetailScreen(
      series: s,
      data: data,
      server: server,
      user: user,
      pass: pass,
    )));
  }
}

// الشاشة الجديدة المزيانة
class SeriesDetailScreen extends StatefulWidget {
  final dynamic series;
  final dynamic data;
  final String server;
  final String user;
  final String pass;

  SeriesDetailScreen({required this.series, required this.data, required this.server, required this.user, required this.pass});

  @override
  _SeriesDetailScreenState createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  late String selectedSeason;
  late List<String> seasons;

  @override
  void initState() {
    super.initState();
    seasons = widget.data['episodes'].keys.toList()..sort((a,b) => int.parse(a).compareTo(int.parse(b)));
    selectedSeason = seasons.first;
  }

  @override
  Widget build(BuildContext context) {
    final episodes = widget.data['episodes'][selectedSeason] as List;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.series['name'], style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.orange),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // المواسم مربعات
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8), // <-- صلحتها هنا
            child: Text(Lang.get('seasons'), style: TextStyle(color: Colors.orange, fontSize: 22, fontWeight: FontWeight.bold)), // ← تبدل
          ),
          Container(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: seasons.length,
              itemBuilder: (ctx, i) {
                final season = seasons[i];
                final isSel = season == selectedSeason;
                return Focus(
                  autofocus: i == 0,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
                      setState(() => selectedSeason = season);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Builder(
                    builder: (ctx2) {
                      final hasFocus = Focus.of(ctx2).hasFocus;
                      return GestureDetector(
                        onTap: () => setState(() => selectedSeason = season),
                        child: Container(
                          width: 140,
                          margin: EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSel? Colors.orange : Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: hasFocus? Colors.white : Colors.transparent, width: 3),
                          ),
                          child: Center(
                            child: Text('${Lang.get('season')} $season', style: TextStyle( // ← تبدل
                              color: isSel? Colors.black : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                            )),
                          ),
                        ),
                      );
                    }
                  ),
                );
              },
            ),
          ),

          // الحلقات مربعات
          Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('${Lang.get('episodes')} - ${Lang.get('season')} $selectedSeason', style: TextStyle(color: Colors.white70, fontSize: 16)), // ← تبدل
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 3.2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: episodes.length,
              itemBuilder: (ctx, i) {
                final ep = episodes[i];
                return Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
                      _playEpisode(ep);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Builder(
                    builder: (ctx2) {
                      final hasFocus = Focus.of(ctx2).hasFocus;
                      return GestureDetector(
                        onTap: () => _playEpisode(ep),
                        child: Container(
                          decoration: BoxDecoration(
                            color: hasFocus? Colors.orange.withOpacity(0.3) : Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: hasFocus? Colors.orange : Colors.grey[700]!, width: 2),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Icon(Icons.play_arrow, color: hasFocus? Colors.orange : Colors.white70, size: 24),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${Lang.get('episode')} ${i+1}', // ← تبدل
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: hasFocus? FontWeight.bold : FontWeight.normal),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _playEpisode(ep) {
    String url = '${widget.server}/series/${widget.user}/${widget.pass}/${ep['id']}.${ep['container_extension']}';
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlayerScreen(url: url, title: ep['title'], logo: widget.series['cover'])
    ));
  }
}
