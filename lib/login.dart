import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'lang.dart';

// ============= LOGIN SELECTION =============
class LoginSelection extends StatefulWidget {
  @override
  _LoginSelectionState createState() => _LoginSelectionState();
}

class _LoginSelectionState extends State<LoginSelection> {
  String _mac = 'AA:BB:CC:DD:EE:FF';
  String _deviceId = '000000';
  String _deviceName = 'ANDROID TV';
  String _currentLang = 'ar';

  // للريموت - زر اللغة
  final FocusNode _langFocusNode = FocusNode();
  bool _langFocused = false;

  // أعلام اللغات
  final Map<String, String> flags = {
    'ar': '🇹🇳',
    'cs': '🇨🇿',
    'fr': '🇫🇷',
    'en': '🇬🇧',
    'de': '🇩🇪',
  };

  @override
  void initState() {
    super.initState();
    _loadLang();
    _getDeviceInfo();
  }

  @override
  void dispose() {
    _langFocusNode.dispose();
    super.dispose();
  }

  _loadLang() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lang = prefs.getString('lang') ?? 'ar';
    await Lang.set(lang);
    setState(() => _currentLang = lang);
  }

  Future<void> _changeLang() async {
    final langs = {
      'ar': 'العربية',
      'cs': 'Čeština',
      'fr': 'Français',
      'en': 'English',
      'de': 'Deutsch',
    };
    final selected = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text('Language / اللغة', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: langs.entries.map((e) => ListTile(
            leading: Text(flags[e.key]!, style: TextStyle(fontSize: 26)), // العلم
            title: Text(e.value, style: TextStyle(color: Colors.white70)),
            trailing: _currentLang == e.key ? Icon(Icons.check, color: Colors.cyanAccent) : null,
            onTap: () => Navigator.pop(c, e.key),
          )).toList(),
        ),
      ),
    );
    if (selected != null && selected != _currentLang) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('lang', selected);
      await Lang.set(selected);
      setState(() => _currentLang = selected);
    }
  }

  _getDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceInfo = DeviceInfoPlugin();
    
    String mac = await getMacAddress();
    String key = prefs.getString('device_id') ?? '';
    String name = 'ANDROID TV';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        name = '${androidInfo.manufacturer} ${androidInfo.model}'.toUpperCase();
      }
    } catch(e) {}

    if (key.isEmpty) {
      key = generateKey();
      await prefs.setString('device_id', key);
    }

    print('🔥 LOGIN FINAL MAC: $mac');
    print('🔥 LOGIN FINAL ID: $key');

    try {
      await Supabase.instance.client.from('devices').upsert({
        'mac_address': mac,
        'activation_key': key,
        'last_seen': DateTime.now().toIso8601String(),
        'device_name': name,
      }, onConflict: 'mac_address');
    } catch (e) {
      print('Supabase Error: $e');
    }

    if (mounted) {
      setState(() {
        _deviceName = name;
        _mac = mac;
        _deviceId = key;
      });
    }

    await _tryAutoLoginFromCloud(mac);
  }

  Future<void> _tryAutoLoginFromCloud(String mac) async {
    try {
      final data = await Supabase.instance.client
          .from('playlists')
          .select()
          .eq('mac', mac)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return;

      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (data['type'] == 'xtream' && data['server_url'] != null) {
        String server = (data['server_url'] as String).trim().replaceAll(RegExp(r'/$'), '');
        String user = data['username'] ?? '';
        String pass = data['password'] ?? '';

        try {
          String url = '$server/player_api.php?username=$user&password=$pass';
          final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 8));
          if (response.statusCode == 200) {
            var d = json.decode(response.body);
            if (d['user_info']?['auth'] == 1) {
              await prefs.setBool('isLoggedIn', true);
              await prefs.setString('loginType', 'xtream');
              await prefs.setString('server', server);
              await prefs.setString('username', user);
              await prefs.setString('password', pass);
              await prefs.setString('xtreamData', response.body);

              if (d['user_info']?['exp_date'] != null) {
                try {
                  int exp = int.parse(d['user_info']['exp_date'].toString());
                  if (exp > 0) {
                    DateTime expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
                    await prefs.setString('expiry', '${expDate.day}/${expDate.month}/${expDate.year}');
                    await prefs.setInt('daysLeft', expDate.difference(DateTime.now()).inDays);
                    
                    try {
                      await Supabase.instance.client.from('devices').update({
                        'expiry_date': expDate.toIso8601String(),
                        'last_seen': DateTime.now().toIso8601String(),
                        'device_name': _deviceName,
                      }).eq('mac_address', mac);
                    } catch (_) {}
                  }
                } catch (_) {}
              }

              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainMenu()));
              }
              return;
            }
          }
        } catch (_) {}
      } else if (data['type'] == 'm3u' && data['url'] != null) {
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('loginType', 'm3u');
        await prefs.setString('m3uUrl', data['url']);
        await prefs.setString('playlistName', data['name'] ?? '');
        await prefs.remove('expiry');

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainMenu()));
        }
      }
    } catch (e) {
      print('AutoLogin Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String qrData = jsonEncode({'mac': _mac, 'id': _deviceId, 'name': _deviceName});
    
    final texts = {
      'ar': {'manual': 'التسجيل اليدوي', 'scan': 'امسح للتسجيل\nالتلقائي'},
      'cs': {'manual': 'MANUÁLNÍ REGISTRACE', 'scan': 'NASKENUJTE PRO\nAUTOMATICKOU\nREGISTRACI'},
      'fr': {'manual': 'ENREGISTREMENT MANUEL', 'scan': 'SCANNEZ POUR\nINSCRIPTION\nAUTOMATIQUE'},
      'en': {'manual': 'MANUAL REGISTRATION', 'scan': 'SCAN ME FOR\nAUTOMATIC\nREGISTRATION'},
      'de': {'manual': 'MANUELLE REGISTRIERUNG', 'scan': 'SCANNEN FÜR\nAUTOMATISCHE\nREGISTRIERUNG'},
    };
    
    final t = texts[_currentLang] ?? texts['en']!;
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/background.jpeg', fit: BoxFit.fill),
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(radius: 30, backgroundImage: AssetImage('assets/avatar.png')),
                          SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: 'MAC: $_mac\nID: $_deviceId'));
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Lang.get('copied')), duration: Duration(seconds: 1)));
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.cyan, width: 2),
                                    boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.5), blurRadius: 15, spreadRadius: 1)],
                                  ),
                                  child: QrImageView(
                                    data: qrData,
                                    size: 110,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.cyan.withOpacity(0.6), width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_deviceName, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
                                      SizedBox(height: 1),
                                      Text('MAC: $_mac', style: TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                      Text('ID: $_deviceId', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Focus(
                        focusNode: _langFocusNode,
                        onFocusChange: (hasFocus) => setState(() => _langFocused = hasFocus),
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent) {
                            if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                              _changeLang();
                              return KeyEventResult.handled;
                            }
                          }
                          return KeyEventResult.ignored;
                        },
                        child: GestureDetector(
                          onTap: _changeLang,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.6),
                              border: Border.all(color: _langFocused ? Colors.cyanAccent : Colors.white30, width: _langFocused ? 3 : 2),
                              boxShadow: _langFocused ? [BoxShadow(color: Colors.cyanAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 1)] : [],
                            ),
                            child: Center(child: Text(flags[_currentLang]!, style: TextStyle(fontSize: 30))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 5),
                
                // *** التعديل الوحيد هنا ***
                Transform.translate(
                  offset: const Offset(0, -120),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LoginCard(title: 'XTREAM CODES', icon: Icons.dns, color: Colors.blue, autofocus: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => XtreamLogin()))),
                          SizedBox(width: 40),
                          _LoginCard(title: 'M3U PLAYLIST', icon: Icons.link, color: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => M3ULogin()))),
                        ],
                      ),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          t['manual']!, 
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 26, 
                            fontWeight: FontWeight.bold, 
                            letterSpacing: 2,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 12, offset: Offset(2, 2))
                            ]
                          )
                        ),
                      ),
                      SizedBox(height: 25),
                      Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('WhatsApp +420 777099379', style: TextStyle(color: Colors.cyan, fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange, width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.orange.withOpacity(0.8), blurRadius: 20, spreadRadius: 2),
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/qr_big.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 5),
                        Container(
                          width: 120,
                          child: Text(
                            t['scan']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900, height: 1.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool autofocus;

  _LoginCard({required this.title, required this.icon, required this.color, required this.onTap, this.autofocus = false});

  @override
  __LoginCardState createState() => __LoginCardState();
}

class __LoginCardState extends State<_LoginCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 240,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _focused ? widget.color : widget.color.withOpacity(0.5), width: _focused ? 4 : 2),
            boxShadow: _focused ? [BoxShadow(color: widget.color, blurRadius: 30, spreadRadius: 5)] : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 48, color: widget.color),
              SizedBox(height: 12),
              Text(widget.title, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class XtreamLogin extends StatefulWidget {
  @override
  _XtreamLoginState createState() => _XtreamLoginState();
}

class _XtreamLoginState extends State<XtreamLogin> {
  final _serverController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  final _serverFocus = FocusNode();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSaved();
    WidgetsBinding.instance.addPostFrameCallback((_) => _serverFocus.requestFocus());
  }

  Future<void> _loadSaved() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverController.text = prefs.getString('server') ?? 'http://';
      _userController.text = prefs.getString('username') ?? '';
      _passController.text = prefs.getString('password') ?? '';
    });
  }

  @override
  void dispose() {
    _serverFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  _login() async {
    setState(() => _loading = true);
    String server = _serverController.text.trim()
        .replaceAll(RegExp(r'/player_api\.php.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'/$'), '');
    String user = _userController.text.trim();
    String pass = _passController.text.trim();

    if (server.isEmpty || user.isEmpty || pass.isEmpty || server == 'http://' || server == 'https://') {
      _showError(Lang.get('fill_all_fields'));
      setState(() => _loading = false);
      return;
    }

    try {
      String url = '$server/player_api.php?username=$user&password=$pass';
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['user_info']['auth'] == 1) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('loginType', 'xtream');
          await prefs.setString('server', server);
          await prefs.setString('username', user);
          await prefs.setString('password', pass);
          await prefs.setString('xtreamData', response.body);
          
          if (data['user_info'] != null && data['user_info']['exp_date'] != null) {
            try {
              int expTimestamp = int.parse(data['user_info']['exp_date'].toString());
              if (expTimestamp > 0) {
                DateTime expDate = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
                String formatted = '${expDate.day}/${expDate.month}/${expDate.year}';
                await prefs.setString('expiry', formatted);
                int daysLeft = expDate.difference(DateTime.now()).inDays;
                await prefs.setInt('daysLeft', daysLeft > 0 ? daysLeft : 0);
                
                String deviceMac = await getMacAddress();
                if (deviceMac.isNotEmpty) {
                  try {
                    await Supabase.instance.client.from('devices').update({
                      'expiry_date': expDate.toIso8601String(),
                      'last_seen': DateTime.now().toIso8601String(),
                    }).eq('mac_address', deviceMac);
                  } catch (_) {}
                }
              }
            } catch(e) {}
          }
          
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainMenu()));
        } else {
          _showError(Lang.get('invalid_credentials'));
        }
      } else {
        _showError(Lang.get('server_error'));
      }
    } catch (e) {
      _showError(Lang.get('connection_failed'));
    }
    setState(() => _loading = false);
  }

  _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpeg', fit: BoxFit.fill),
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                SizedBox(height: 20),
                SizedBox(height: 40),
                Container(
                  width: 500,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _InputField(controller: _serverController, hint: Lang.get('server_url'), color: Colors.cyan, focusNode: _serverFocus, nextFocus: _userFocus),
                      SizedBox(height: 20),
                      _InputField(controller: _userController, hint: Lang.get('username'), color: Colors.cyan, focusNode: _userFocus, nextFocus: _passFocus, prevFocus: _serverFocus),
                      SizedBox(height: 20),
                      _InputField(controller: _passController, hint: Lang.get('password'), color: Colors.cyan, obscure: true, focusNode: _passFocus, prevFocus: _userFocus, textInputAction: TextInputAction.done, onSubmitted: (_) => _login()),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Button(text: Lang.get('login'), color: Colors.cyan, onPressed: _loading ? null : _login),
                          SizedBox(width: 20),
                          _Button(text: Lang.get('cancel'), color: Colors.grey, onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      SizedBox(height: 50),
                    ],
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

class M3ULogin extends StatefulWidget {
  @override
  _M3ULoginState createState() => _M3ULoginState();
}

class _M3ULoginState extends State<M3ULogin> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  final _urlFocus = FocusNode();
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSaved();
    WidgetsBinding.instance.addPostFrameCallback((_) => _urlFocus.requestFocus());
  }

  Future<void> _loadSaved() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('m3uUrl') ?? 'http://';
      _nameController.text = prefs.getString('playlistName') ?? '';
    });
  }

  @override
  void dispose() {
    _urlFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  _login() async {
    setState(() => _loading = true);
    String url = _urlController.text.trim();
    if (url.isEmpty || url == 'http://' || url == 'https://') {
      _showError(Lang.get('enter_m3u_url'));
      setState(() => _loading = false);
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('loginType', 'm3u');
    await prefs.setString('m3uUrl', url);
    await prefs.setString('playlistName', _nameController.text.trim());
    await prefs.remove('expiry');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainMenu()));
  }

  _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpeg', fit: BoxFit.fill),
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                SizedBox(height: 20),
                SizedBox(height: 40),
                Container(
                  width: 500,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _InputField(controller: _urlController, hint: Lang.get('m3u_url'), color: Colors.red, focusNode: _urlFocus, nextFocus: _nameFocus),
                      SizedBox(height: 20),
                      _InputField(controller: _nameController, hint: Lang.get('playlist_name'), color: Colors.red, focusNode: _nameFocus, prevFocus: _urlFocus, textInputAction: TextInputAction.done, onSubmitted: (_) => _login()),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Button(text: Lang.get('login'), color: Colors.red, onPressed: _loading ? null : _login),
                          SizedBox(width: 20),
                          _Button(text: Lang.get('cancel'), color: Colors.grey, onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      SizedBox(height: 50),
                    ],
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

class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final Color color;
  final bool obscure;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final FocusNode? prevFocus;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;

  _InputField({required this.controller, required this.hint, required this.color, this.obscure = false, this.focusNode, this.nextFocus, this.prevFocus, this.textInputAction, this.onSubmitted});

  @override
  __InputFieldState createState() => __InputFieldState();
}

class __InputFieldState extends State<_InputField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.nextFocus?.requestFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            widget.prevFocus?.requestFocus();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      }, // هذي كانت ناقصة
      child: TextField(
        controller: widget.controller,
        obscureText: widget.obscure,
        focusNode: widget.focusNode,
        textInputAction: widget.textInputAction ?? TextInputAction.next,
        onSubmitted: (value) {
          if (widget.onSubmitted != null) {
            widget.onSubmitted!(value);
          } else if (widget.nextFocus != null) {
            widget.nextFocus!.requestFocus();
          }
        },
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.black.withOpacity(0.5),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: widget.color, width: 2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: widget.color, width: 3)),
        ),
      ),
    );
  }
}

class _Button extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback? onPressed;

  _Button({required this.text, required this.color, this.onPressed});

  @override
  __ButtonState createState() => __ButtonState();
}

class __ButtonState extends State<_Button> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
            if (widget.onPressed != null) widget.onPressed!();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: _focused ? widget.color : Colors.transparent, width: 3)),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: widget.color, padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          child: Text(widget.text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
