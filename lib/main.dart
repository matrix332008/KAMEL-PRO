import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'live_tv.dart';
import 'epg.dart';
import 'filmes.dart';
import 'series.dart';
import 'favorites.dart';
import 'ajustes.dart';
import 'player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(KamelProApp());
}

class KamelProApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KAMEL PRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: TextTheme(bodyMedium: TextStyle(fontFamily: 'Arial')),
      ),
      home: SplashScreen(),
    );
  }
}

// ============= SPLASH SCREEN =============
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  _checkLogin() async {
    await Future.delayed(Duration(seconds: 2));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    if (isLoggedIn) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainMenu()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginSelection()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/avatar.png'),
                backgroundColor: Colors.transparent,
              ),
              SizedBox(height: 20),
              Image.asset('assets/logo.png', width: 300),
            ],
          ),
        ),
      ),
    );
  }
}

// ============= LOGIN SELECTION =============
class LoginSelection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/avatar.png'),
                  ),
                  Spacer(),
                  Image.asset('assets/logo.png', width: 200),
                  Spacer(),
                  SizedBox(width: 60),
                ],
              ),
            ),
            Spacer(),
            Text(
              'LOGIN METHOD',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.cyan, blurRadius: 20)],
              ),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LoginCard(
                  title: 'XTREAM CODES',
                  icon: Icons.dns,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, 
                    MaterialPageRoute(builder: (_) => XtreamLogin())),
                ),
                SizedBox(width: 60),
                _LoginCard(
                  title: 'M3U PLAYLIST',
                  icon: Icons.link,
                  color: Colors.red,
                  onTap: () => Navigator.push(context, 
                    MaterialPageRoute(builder: (_) => M3ULogin())),
                ),
              ],
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.whatsapp, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'WhatsApp +420 777099379',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
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
  
  _LoginCard({required this.title, required this.icon, required this.color, required this.onTap});
  
  @override
  __LoginCardState createState() => __LoginCardState();
}

class __LoginCardState extends State<_LoginCard> {
  bool _focused = false;
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 280,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _focused ? widget.color : widget.color.withOpacity(0.5),
              width: _focused ? 4 : 2,
            ),
            boxShadow: _focused ? [
              BoxShadow(color: widget.color, blurRadius: 30, spreadRadius: 5)
            ] : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 60, color: widget.color),
              SizedBox(height: 20),
              Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

  _login() async {
    setState(() => _loading = true);
    String server = _serverController.text.trim();
    String user = _userController.text.trim();
    String pass = _passController.text.trim();
    
    if (server.isEmpty || user.isEmpty || pass.isEmpty) {
      _showError('Please fill all fields');
      setState(() => _loading = false);
      return;
    }

    try {
      String url = '$server/player_api.php?username=$user&password=$pass';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['user_info']['auth'] == 1) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('loginType', 'xtream');
          await prefs.setString('server', server);
          await prefs.setString('username', user);
          await prefs.setString('password', pass);
          
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(radius: 30, backgroundImage: AssetImage('assets/avatar.png')),
                  Spacer(),
                  Image.asset('assets/logo.png', width: 200),
                  Spacer(),
                  SizedBox(width: 60),
                ],
              ),
            ),
            Spacer(),
            Container(
              width: 500,
              child: Column(
                children: [
                  _InputField(controller: _serverController, hint: 'SERVER URL', color: Colors.cyan),
                  SizedBox(height: 20),
                  _InputField(controller: _userController, hint: 'USERNAME', color: Colors.cyan),
                  SizedBox(height: 20),
                  _InputField(controller: _passController, hint: 'PASSWORD', color: Colors.cyan, obscure: true),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Button(text: 'LOGIN', color: Colors.cyan, onPressed: _loading ? null : _login),
                      SizedBox(width: 20),
                      _Button(text: 'CANCEL', color: Colors.grey, onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ],
              ),
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.whatsapp, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text('WhatsApp +420 777099379', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
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

  _login() async {
    setState(() => _loading = true);
    String url = _urlController.text.trim();
    
    if (url.isEmpty) {
      _showError('Please enter M3U URL');
      setState(() => _loading = false);
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('loginType', 'm3u');
    await prefs.setString('m3uUrl', url);
    await prefs.setString('playlistName', _nameController.text.trim());
    
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainMenu()));
  }

  _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(radius: 30, backgroundImage: AssetImage('assets/avatar.png')),
                  Spacer(),
                  Image.asset('assets/logo.png', width: 200),
                  Spacer(),
                  SizedBox(width: 60),
                ],
              ),
            ),
            Spacer(),
            Container(
              width: 500,
              child: Column(
                children: [
                  _InputField(controller: _urlController, hint: 'M3U URL', color: Colors.red),
                  SizedBox(height: 20),
                  _InputField(controller: _nameController, hint: 'PLAYLIST NAME (Optional)', color: Colors.red),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Button(text: 'LOGIN', color: Colors.red, onPressed: _loading ? null : _login),
                      SizedBox(width: 20),
                      _Button(text: 'CANCEL', color: Colors.grey, onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ],
              ),
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.whatsapp, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text('WhatsApp +420 777099379', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= MAIN MENU =============
class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginSelection()));
  }

  _navigateToLiveTV() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTV()));
  }

  _navigateToEPG() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EPGScreen()));
  }

  _navigateToFilmes() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => FilmesScreen()));
  }

  _navigateToSeries() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesScreen()));
  }

  _navigateToFavorites() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesScreen()));
  }

  _navigateToAjustes() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AjustesScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(radius: 30, backgroundImage: AssetImage('assets/avatar.png')),
                  SizedBox(width: 20),
                  Image.asset('assets/logo.png', width: 200),
                  Spacer(),
                  _LogoutButton(onPressed: _logout),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MainCard(title: 'LIVE TV', image: 'assets/live.png', color: Colors.blue, onTap: _navigateToLiveTV),
                        SizedBox(width: 40),
                        _MainCard(title: 'EPG', image: 'assets/epg.png', color: Colors.red, onTap: _navigateToEPG),
                      ],
                    ),
                    SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MainCard(title: 'FILMES', image: 'assets/filmes.png', color: Colors.red, onTap: _navigateToFilmes),
                        SizedBox(width: 40),
                        _MainCard(title: 'SERIES', image: 'assets/series.png', color: Colors.orange, onTap: _navigateToSeries),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 30, left: 60, right: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BottomButton(icon: Icons.favorite, label: 'FAVORITOS', color: Colors.red, onTap: _navigateToFavorites),
                  Row(
                    children: [
                      Icon(Icons.whatsapp, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('WhatsApp +420 777099379', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  _LanguageButton(onTap: _navigateToAjustes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainCard extends StatefulWidget {
  final String title;
  final String image;
  final Color color;
  final VoidCallback onTap;
  
  _MainCard({required this.title, required this.image, required this.color, required this.onTap});
  
  @override
  __MainCardState createState() => __MainCardState();
}

class __MainCardState extends State<_MainCard> {
  bool _focused = false;
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 300,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color, width: _focused ? 4 : 2),
            boxShadow: _focused ? [
              BoxShadow(color: widget.color, blurRadius: 30, spreadRadius: 5)
            ] : [],
            image: DecorationImage(
              image: AssetImage(widget.image),
              fit: BoxFit.cover,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  _BottomButton({required this.icon, required this.label, required this.color, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            SizedBox(height: 5),
            Text(label, style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final VoidCallback onTap;
  _LanguageButton({required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Row(
              children: [
                Text('🇹🇳', style: TextStyle(fontSize: 24)),
                SizedBox(width: 5),
                Text('🇫🇷', style: TextStyle(fontSize: 24)),
                SizedBox(width: 5),
                Text('🇨🇿', style: TextStyle(fontSize: 24)),
              ],
            ),
            SizedBox(height: 5),
            Text('AJUSTES', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;
  _LogoutButton({required this.onPressed});
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white70),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text('LOG OUT', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color color;
  final bool obscure;
  
  _InputField({required this.controller, required this.hint, required this.color, this.obscure = false});
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.black.withOpacity(0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: color, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: color, width: 3),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onPressed;
  
  _Button({required this.text, required this.color, this.onPressed});
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
