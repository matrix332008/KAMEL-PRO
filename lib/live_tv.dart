import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'player.dart';
import 'lang.dart';

class LiveTV extends StatefulWidget {
  @override
  _LiveTVState createState() => _LiveTVState();
}

class _LiveTVState extends State<LiveTV> {
  List channels = [];
  List groups = [];
  String sel = 'All';
  bool loading = true;
  String _search = '';
  final _searchController = TextEditingController();
  final FocusNode _mainFocusNode = FocusNode(); // ✅ جديد للصوت
  final FocusNode _searchFocusNode = FocusNode(); // ✅ جديد باش نهبطو من البحث

  // ✅ Channel للصوت - لازم تزيد MainActivity.kt مبعد
  static const platform = MethodChannel('volume_channel');

  @override
  void initState() {
    super.initState();
    _load();
    _mainFocusNode.requestFocus(); // ✅ جديد
  }

  @override
  void dispose() {
    _mainFocusNode.dispose(); // ✅ جديد
    _searchFocusNode.dispose(); // ✅ جديد
    _searchController.dispose();
    super.dispose();
  }

  // ✅ جديد: نشدو ازرار الصوت قبل ما يمشو للـ Focus
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
        _changeVolume(true);
        return KeyEventResult.handled; // ما نخليوش يكمل
      }
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
        _changeVolume(false);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeMute) {
        _toggleMute();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // ✅ جديد: نبعثو للـ Native Android باش يزيد/ينقص الصوت
  void _changeVolume(bool up) async {
    try {
      await platform.invokeMethod('setVolume', {'up': up});
    } catch (e) {
      print('Volume Error: $e');
    }
  }

  void _toggleMute() async {
    try {
      await platform.invokeMethod('toggleMute');
    } catch (e) {
      print('Mute Error: $e');
    }
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    String server = (p.getString('server') ?? '').replaceAll(RegExp(r'/$'), '');
    String user = p.getString('username') ?? '';
    String pass = p.getString('password') ?? '';
    try {
      final cRes = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_live_categories')).timeout(Duration(seconds: 10));
      final chRes = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_live_streams')).timeout(Duration(seconds: 15));
      if (chRes.statusCode == 200) channels = json.decode(chRes.body);
      if (cRes.statusCode == 200) {
        var cats = json.decode(cRes.body);
        groups = [{'category_id': 'All', 'category_name': Lang.get('all')}];
        for (var c in cats) {
          groups.add({'category_id': c['category_id'].toString(), 'category_name': c['category_name']});
        }
      }
    } catch (e) {}
    if (groups.isEmpty) groups = [{'category_id': 'All', 'category_name': Lang.get('all')}];
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    var filtered = sel == 'All' ? channels : channels.where((e) => e['category_id'].toString() == sel).toList();
    if (_search.isNotEmpty) {
      filtered = filtered.where((e) => (e['name'] ?? '').toString().toLowerCase().contains(_search.toLowerCase())).toList();
    }
    
    // ✅ لفينا كل شي بـ Focus
    return Focus(
      focusNode: _mainFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0f0c29),
                Color(0xFF302b63),
                Color(0xFF24243e),
              ],
            ),
          ),
          child: SafeArea(
            child: loading
                ? Center(child: CircularProgressIndicator(color: Colors.cyan))
                : Padding(
                    padding: EdgeInsets.only(left: 30, right: 20, top: 10, bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 280,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.arrow_back, color: Colors.white), 
                                      onPressed: () => Navigator.pop(context)
                                    ),
                                    SizedBox(width: 8),
                                    Text(Lang.get('categories'), style: TextStyle(color: Colors.cyan, fontSize: 22, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  itemCount: groups.length,
                                  itemBuilder: (_, i) {
                                    final g = groups[i];
                                    final active = g['category_id'] == sel;
                                    return Focus(
                                      autofocus: i == 0,
                                      onKeyEvent: (node, event) {
                                        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
                                          setState(() => sel = g['category_id']);
                                          return KeyEventResult.handled;
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: Builder(
                                        builder: (ctx) {
                                          final hasFocus = Focus.of(ctx).hasFocus;
                                          return AnimatedContainer(
                                            duration: Duration(milliseconds: 150),
                                            margin: EdgeInsets.symmetric(vertical: 3),
                                            decoration: BoxDecoration(
                                              color: hasFocus ? Colors.cyan.withOpacity(0.3) : (active ? Colors.cyan.withOpacity(0.15) : Colors.transparent),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: hasFocus ? Colors.cyan : (active ? Colors.cyan.withOpacity(0.5) : Colors.transparent),
                                                width: hasFocus ? 2 : 1,
                                              ),
                                            ),
                                            child: ListTile(
                                              title: Text(
                                                g['category_name'], 
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: hasFocus || active ? Colors.cyan : Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: hasFocus || active ? FontWeight.bold : FontWeight.normal,
                                                )
                                              ),
                                              onTap: () => setState(() => sel = g['category_id']),
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
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                height: 50,
                                margin: EdgeInsets.only(bottom: 10, top: 5, right: 10),
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.search, color: Colors.cyan, size: 24),
                                    SizedBox(width: 10),
                                    Expanded(
                                      // ✅ هذا الكل جديد باش نهبطو من البحث
                                      child: KeyboardListener(
                                        focusNode: _searchFocusNode,
                                        onKeyEvent: (event) {
                                          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                            _searchFocusNode.unfocus();
                                            FocusScope.of(context).focusInDirection(TraversalDirection.down);
                                          }
                                        },
                                        child: TextField(
                                          controller: _searchController,
                                          focusNode: _searchFocusNode,
                                          onChanged: (v) => setState(() => _search = v),
                                          style: TextStyle(color: Colors.white, fontSize: 18),
                                          decoration: InputDecoration(
                                            hintText: Lang.get('search_channel'),
                                            hintStyle: TextStyle(color: Colors.white54),
                                            border: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_search.isNotEmpty)
                                      IconButton(
                                        icon: Icon(Icons.clear, color: Colors.white54),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _search = '');
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: GridView.builder(
                                  padding: EdgeInsets.all(10),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    childAspectRatio: 0.85,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) {
                                    final ch = filtered[i];
                                    final logo = ch['stream_icon'] ?? '';
                                    return Focus(
                                      autofocus: i == 0 && sel == 'All' && _search.isEmpty,
                                      onKeyEvent: (node, event) {
                                        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
                                          _openChannel(ch, filtered, i);
                                          return KeyEventResult.handled;
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: Builder(
                                        builder: (ctx) {
                                          final hasFocus = Focus.of(ctx).hasFocus;
                                          return GestureDetector(
                                            onTap: () => _openChannel(ch, filtered, i),
                                            child: AnimatedContainer(
                                              duration: Duration(milliseconds: 150),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF1A1A1A).withOpacity(0.8),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(color: hasFocus ? Colors.cyan : Colors.white12, width: hasFocus ? 3 : 1),
                                                boxShadow: hasFocus ? [BoxShadow(color: Colors.cyan.withOpacity(0.4), blurRadius: 12)] : [],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    logo.isNotEmpty
                                                        ? Image.network(logo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.tv, size: 50, color: Colors.white24)))
                                                        : Center(child: Icon(Icons.tv, size: 50, color: Colors.white24)),
                                                    Positioned(
                                                      bottom: 0,
                                                      left: 0,
                                                      right: 0,
                                                      child: Container(
                                                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)]),
                                                        ),
                                                        child: Text(
                                                          ch['name'] ?? '',
                                                          textAlign: TextAlign.center,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: hasFocus ? FontWeight.bold : FontWeight.normal),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _openChannel(ch, list, i) async {
    final p = await SharedPreferences.getInstance();
    String server = p.getString('server') ?? '';
    String user = p.getString('username') ?? '';
    String pass = p.getString('password') ?? '';
    String url = '$server/live/$user/$pass/${ch['stream_id']}.ts';
    
    final channelList = list.map((e) => {
      'name': e['name'],
      'url': '$server/live/$user/$pass/${e['stream_id']}.ts',
      'logo': e['stream_icon'],
    }).toList();

    await Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(
      url: url,
      title: ch['name'],
      logo: ch['stream_icon'],
      channelList: channelList,
      currentIndex: i,
    )));
    if (mounted) setState(() {});
  }
}
