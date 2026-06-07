import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'lang.dart';
import 'main.dart';

class AjustesScreen extends StatefulWidget {
  @override
  _AjustesScreenState createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  String _currentLang = 'ar';
  String _mac = '...';
  String _deviceId = '...';
  String _deviceName = '...'; // جديد
  String _expiry = ''; // جديد

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
    {'icon': Icons.qr_code, 'title': 'qr_code', 'action': 'qr'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLang();
    _getDeviceInfo();
  }

  _loadLang() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _currentLang = prefs.getString('lang')?? 'ar');
  }

  _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final prefs = await SharedPreferences.getInstance();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final id = androidInfo.id;
        setState(() {
          _deviceName = '${androidInfo.manufacturer} ${androidInfo.model}'.toUpperCase();
          _deviceId = id.hashCode.abs().toString().padLeft(6, '0').substring(0,6);
          _mac = id.padRight(12,'0').substring(0,12).toUpperCase()
              .replaceAllMapped(RegExp(r'.{2}'), (m) => '${m.group(0)}:')
              .replaceAll(RegExp(r':$'), '');
        });
      }
      // تاريخ الانتهاء - أول مرة يعمل سنة
      if (!prefs.containsKey('expiry')) {
        final expiry = DateTime.now().add(Duration(days: 365));
        await prefs.setString('expiry', '${expiry.day}/${expiry.month}/${expiry.year}');
      }
      setState(() => _expiry = prefs.getString('expiry') ?? '');
    } catch(e) {
      setState(() {
        _deviceName = 'ANDROID TV';
        _mac = '9F:93:6B:11:F3:17';
        _deviceId = '727828';
        _expiry = '7/6/2027';
      });
    }
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
      case 'qr':
        _showQrDialog();
        break;
      case 'player':
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exo Player actif ✓')));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Lang.get('bientot'))));
    }
  }

  void _showQrDialog() {
    final data = 'DEVICE:$_deviceName|MAC:$_mac|ID:$_deviceId|EXP:$_expiry';
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Color(0xFF1A1A2E),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('KAMEL PRO', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        Container(
          color: Colors.white,
          padding: EdgeInsets.all(15),
          child: QrImageView(data: data, size: 200),
        ),
        SizedBox(height: 15),
        Text(_deviceName, style: TextStyle(color: Colors.white70, fontSize: 14)),
        Text(_mac, style: TextStyle(color: Colors.cyan, fontSize: 18, fontWeight: FontWeight.bold)),
        Text('ID: $_deviceId  •  Exp: $_expiry', style: TextStyle(color: Colors.orange, fontSize: 13)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Fermer', style: TextStyle(color: Colors.white70)))
      ],
    ));
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
            // Footer MAC + QR - محدث
            Padding(
              padding: EdgeInsets.only(bottom: 25),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 40),
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_deviceName, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          SizedBox(height: 2),
                          Text('MAC: $_mac', style: TextStyle(color: Colors.cyan, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('ID: $_deviceId  •  Exp: $_expiry', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.copy, color: Colors.white70),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: 'Device: $_deviceName\nMAC: $_mac\nID: $_deviceId\nExpire: $_expiry'));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم النسخ ✓')));
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.qr_code_2, color: Colors.cyan, size: 28),
                          onPressed: _showQrDialog,
                        ),
                        IconButton(
                          icon: Icon(Icons.share, color: Colors.cyan),
                          onPressed: () {
                            Share.share('KAMEL PRO\nDevice: $_deviceName\nMAC: $_mac\nID: $_deviceId\nExpire: $_expiry');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
