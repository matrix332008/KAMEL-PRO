import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'player.dart';

class LiveTV extends StatefulWidget {
  @override
  _LiveTVState createState() => _LiveTVState();
}

class _LiveTVState extends State<LiveTV> {
  List channels = [];
  List groups = [];
  String sel = 'All';
  bool loading = true;
  int groupIndex = 0;
  final FocusNode _leftFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
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
        groups = [{'category_id': 'All', 'category_name': 'الكل'}];
        for (var c in cats) {
          groups.add({'category_id': c['category_id'].toString(), 'category_name': c['category_name']});
        }
      }
    } catch (e) {}
    if (groups.isEmpty) groups = [{'category_id': 'All', 'category_name': 'الكل'}];
    setState(() => loading = false);
    // رجع الفوكس لليسار بعد التحميل
    WidgetsBinding.instance.addPostFrameCallback((_) => _leftFocus.requestFocus());
  }

  @override
  void dispose() {
    _leftFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = sel == 'All' ? channels : channels.where((e) => e['category_id'].toString() == sel).toList();
    return Scaffold(
      backgroundColor: Colors.black,
      body: loading
          ? Center(child: CircularProgressIndicator(color: Colors.cyan))
          : FocusTraversalGroup(
              policy: WidgetOrderTraversalPolicy(),
              child: Row(
                children: [
                  // الباقات على اليسار
                  Container(
                    width: 260,
                    color: Colors.black87,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                              Text('الباقات', style: TextStyle(color: Colors.cyan, fontSize: 20)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: groups.length,
                            itemBuilder: (_, i) {
                              final g = groups[i];
                              final active = g['category_id'] == sel;
                              return Focus(
                                focusNode: i == 0 ? _leftFocus : null,
                                autofocus: i == groupIndex,
                                onKeyEvent: (node, event) {
                                  if (event is KeyDownEvent) {
                                    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                      setState(() => groupIndex = (i + 1) % groups.length);
                                      return KeyEventResult.handled;
                                    }
                                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                      setState(() => groupIndex = (i - 1 + groups.length) % groups.length);
                                      return KeyEventResult.handled;
                                    }
                                    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                      FocusScope.of(context).nextFocus();
                                      return KeyEventResult.handled;
                                    }
                                    if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                                      setState(() {
                                        sel = g['category_id'];
                                        groupIndex = i;
                                      });
                                      return KeyEventResult.handled;
                                    }
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: Builder(
                                  builder: (ctx) {
                                    final hasFocus = Focus.of(ctx).hasFocus;
                                    return Container(
                                      color: hasFocus ? Colors.cyan.withOpacity(0.3) : (active ? Colors.cyan.withOpacity(0.15) : Colors.transparent),
                                      child: ListTile(
                                        title: Text(g['category_name'], style: TextStyle(color: hasFocus || active ? Colors.cyan : Colors.white, fontWeight: hasFocus ? FontWeight.bold : FontWeight.normal)),
                                        onTap: () => setState(() {
                                          sel = g['category_id'];
                                          groupIndex = i;
                                        }),
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
                  // القنوات
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.all(20),
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
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.arrowLeft && i % 5 == 0) {
                                _leftFocus.requestFocus();
                                return KeyEventResult.handled;
                              }
                              if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                                _openChannel(ch, filtered, i);
                                return KeyEventResult.handled;
                              }
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
                                    color: Color(0xFF1A1A1A),
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
                                          bottom: 0, left: 0, right: 0,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.85)]),
                                            ),
                                            child: Text(
                                              ch['name'] ?? '',
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: hasFocus ? FontWeight.bold : FontWeight.normal),
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
    // كي ترجع من البلاير، رجع الفوكس لليسار
    _leftFocus.requestFocus();
  }
}
