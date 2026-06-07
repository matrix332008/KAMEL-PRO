import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lang.dart';
import 'main.dart';

class AjustesScreen extends StatefulWidget {
  @override
  _AjustesScreenState createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  String _currentLang = 'ar';

  final List<Map<String, dynamic>> _items = [
    {'icon': Icons.playlist_add, 'title': 'ajouter_liste', 'action': 'playlist'},
    {'icon': Icons.lock, 'title': 'parental', 'action': 'parental'},
    {'icon': Icons.swap_horiz, 'title': 'changer_liste', 'action': 'change'},
    {'icon': Icons.language, 'title': 'changer_langue', 'action': 'lang'},
    {'icon': Icons.grid_view, 'title': 'disposition', 'action': 'layout'},
    {'icon': Icons.visibility_off, 'title': 'masquer_live', 'action': 'hide_live'},
    {'icon': Icons.visibility_off, 'title': 'masquer_vod', 'action': 'hide_vod'},
    {'icon': Icons.visibility_off, 'title': 'masquer_series', 'action': 'hide_series'},
    {'icon': Icons.history, 'title': 'clear_history', 'action': 'clear'},
    {'icon': Icons.movie_filter, 'title': 'effacer_films', 'action': 'clear_films'},
    {'icon': Icons.tv_off, 'title': 'effacer_series', 'action': 'clear_series'},
    {'icon': Icons.sort_by_alpha, 'title': 'tri_chaines', 'action': 'sort'},
    {'icon': Icons.live_tv, 'title': 'live_format', 'action': 'format'},
    {'icon': Icons.play_circle, 'title': 'select_player', 'action': 'player'},
    {'icon': Icons.extension, 'title': 'acteurs_externes', 'action': 'external'},
    {'icon': Icons.update, 'title': 'mise_a_jour', 'action': 'update'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  _loadLang() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _currentLang = prefs.getString('lang')?? 'ar');
  }

  _changeLang(String lang) async {
    await Lang.set(lang);
    setState(() => _currentLang = lang);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => MainMenu()), (route) => false);
  }

  void _handleAction(String action) {
    switch (action) {
      case 'lang':
        _showLangDialog();
        break;
      case 'player':
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exo Player actif ✓')));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Lang.get('bientot'))));
    }
  }

  void _showLangDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Color(0xFF1A1A2E),
      title: Text(Lang.get('choisir_langue'), style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _langOption('🇹🇳', 'عربي', 'ar'),
        _langOption('🇫🇷', 'Français', 'fr'),
        _langOption('🇨🇿', 'Čeština', 'cs'),
      ]),
    ));
  }

  Widget _langOption(String flag, String name, String code) {
    return ListTile(
      leading: Text(flag, style: TextStyle(fontSize: 28)),
      title: Text(name, style: TextStyle(color: Colors.white)),
      trailing: _currentLang == code? Icon(Icons.check, color: Colors.cyan) : null,
      onTap: () { Navigator.pop(context); _changeLang(code); },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(40, 50, 30, 20),
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.arrow_back, color: Colors.white, size: 32), onPressed: () => Navigator.pop(context)),
                  SizedBox(width: 15),
                  Text('Paramètres', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Focus(
                      autofocus: index == 0,
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
                          _handleAction(item['action']);
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Builder(builder: (ctx) {
                        final hasFocus = Focus.of(ctx).hasFocus;
                        return GestureDetector(
                          onTap: () => _handleAction(item['action']),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: hasFocus? [Colors.cyan.withOpacity(0.8), Colors.blue.withOpacity(0.8)] : [Color(0xFF1A1A2E), Color(0xFF16213E)]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: hasFocus? Colors.cyan : Colors.white24, width: hasFocus? 3 : 1),
                              boxShadow: hasFocus? [BoxShadow(color: Colors.cyan.withOpacity(0.4), blurRadius: 12)] : [],
                            ),
                            child: Row(
                              children: [
                                SizedBox(width: 15),
                                Icon(item['icon'], color: hasFocus? Colors.black : Colors.cyan, size: 28),
                                SizedBox(width: 12),
                                Expanded(child: Text(Lang.get(item['title']), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: hasFocus? Colors.black : Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
                              ],
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
            // Footer infos
            Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  Text('Adresse Mac: 9F:93:6B:11:F3:17', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('Clé de l\'appareil: 727828', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
