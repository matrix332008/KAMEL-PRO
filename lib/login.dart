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

// ============= LOGIN SELECTION =============
class LoginSelection extends StatefulWidget {
  @override
  _LoginSelectionState createState() => _LoginSelectionState();
}

class _LoginSelectionState extends State<LoginSelection> {
  String _mac = '...';
  String _deviceId = '...';
  String _deviceName = '...';

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
  }

  _getDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceInfo = DeviceInfoPlugin();
    
    String mac = prefs.getString('device_mac') ?? '';
    String key = prefs.getString('device_key') ?? '';
    String name = 'ANDROID TV';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        name = '${androidInfo.manufacturer} ${androidInfo.model}'.toUpperCase();
      }
    } catch(e) {}

    if (mac.isEmpty) {
      mac = await getMacAddress();
    }
    if (key.isEmpty) {
      key = generateKey();
      await prefs.setString('device_key', key);
      await Supabase.instance.client.from('devices').upsert({
        'mac_address': mac,
        'activation_key': key,
        'last_seen': DateTime.now().toIso8601String(),
      }, onConflict: 'mac_address');
    }

    setState(() {
      _deviceName = name;
      _mac = mac;
      _deviceId = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    String qrData = jsonEncode({'mac': _mac, 'id': _deviceId, 'name': _deviceName});
    
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpeg', fit: BoxFit.fill),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(radius: 30, backgroundImage: AssetImage('assets/avatar.png')),
                    Spacer(),
                    SizedBox(width: 60),
                  ],
                ),
              ),
              Spacer(),
              Text('LOGIN METHOD', style: TextStyle(color: Colors.cyanAccent, fontSize: 28, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.cyan, blurRadius: 20)])),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LoginCard(title: 'XTREAM CODES', icon: Icons.dns, color: Colors.blue, autofocus: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => XtreamLogin()))),
                  SizedBox(width: 60),
                  _LoginCard(title: 'M3U PLAYLIST', icon: Icons.link, color: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => M3ULogin()))),
                ],
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('WhatsApp +420 777099379', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 35,
            left: 25,
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: 'MAC: $_mac\nID: $_deviceId'));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ البيانات ✓'), duration: Duration(seconds: 1)));
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
                      size: 85,
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
          ),
        ],
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
          width: 280,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _focused ? widget.color : widget.color.withOpacity(0.5), width: _focused ? 4 : 2),
            boxShadow: _focused ? [BoxShadow(color: widget.color, blurRadius: 30, spreadRadius: 5)] : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 60, color: widget.color),
              SizedBox(height: 20),
              Text(widget.title, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============= XTREAM LOGIN =============
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
      _showError('Please fill all fields');
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
              }
            } catch(e) {}
          }
          
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainMenu()));
        } else {
          _showError('Invalid credentials');
        }
      } else {
        _showError('Server error');
      }
    } catch (e) {
      _showError('Connection failed');
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
                      _InputField(controller: _serverController, hint: 'SERVER URL', color: Colors.cyan, focusNode: _serverFocus, nextFocus: _userFocus),
                      SizedBox(height: 20),
                      _InputField(controller: _userController, hint: 'USERNAME', color: Colors.cyan, focusNode: _userFocus, nextFocus: _passFocus, prevFocus: _serverFocus),
                      SizedBox(height: 20),
                      _InputField(controller: _passController, hint: 'PASSWORD', color: Colors.cyan, obscure: true, focusNode: _passFocus, prevFocus: _userFocus, textInputAction: TextInputAction.done, onSubmitted: (_) => _login()),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Button(text: 'LOGIN', color: Colors.cyan, onPressed: _loading ? null : _login),
                          SizedBox(width: 20),
                          _Button(text: 'CANCEL', color: Colors.grey, onPressed: () => Navigator.pop(context)),
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

// ============= M3U LOGIN =============
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
      _showError('Please enter M3U URL');
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
                      _InputField(controller: _urlController, hint: 'M3U URL', color: Colors.red, focusNode: _urlFocus, nextFocus: _nameFocus),
                      SizedBox(height: 20),
                      _InputField(controller: _nameController, hint: 'PLAYLIST NAME (Optional)', color: Colors.red, focusNode: _nameFocus, prevFocus: _urlFocus, textInputAction: TextInputAction.done, onSubmitted: (_) => _login()),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Button(text: 'LOGIN', color: Colors.red, onPressed: _loading ? null : _login),
                          SizedBox(width: 20),
                          _Button(text: 'CANCEL', color: Colors.grey, onPressed: () => Navigator.pop(context)),
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
      },
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
