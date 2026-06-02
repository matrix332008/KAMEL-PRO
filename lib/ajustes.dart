import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

class AjustesScreen extends StatefulWidget {
  @override
  _AjustesScreenState createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  String _currentLanguage = 'AR';
  String _expiryDate = '';
  String _username = '';
  String _server = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language')?? 'AR';
    _username = prefs.getString('username')?? '';
    _server = prefs.getString('server')?? '';
    String password = prefs.getString('password')?? '';

    // جلب تاريخ الانتهاء من السيرفر
    try {
      String url = '$_server/player_api.php?username=$_username&password=$password';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['user_info']!= null && data['user_info']['exp_date']!= null) {
          int expTimestamp = int.parse(data['user_info']['exp_date'].toString());
          DateTime expDate = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
          _expiryDate = '${expDate.day}/${expDate.month}/${expDate.year}';
        }
      }
    } catch (e) {
      _expiryDate = 'غير متوفر';
    }
    setState(() => _loading = false);
  }

  _changeLanguage(String lang) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    setState(() => _currentLanguage = lang);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تغيير اللغة ✅'), backgroundColor: Colors.green),
    );
  }

  _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
        content: Text('هل انت متأكد من تسجيل الخروج؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('الغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginSelection()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('تسجيل الخروج'),
          ),
        ],
      ),
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
            // Header
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.black.withOpacity(0.7),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 20),
                  Icon(Icons.settings, color: Colors.cyan, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'AJUSTES / الاعدادات',
                    style: TextStyle(color: Colors.cyan, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                ? Center(child: CircularProgressIndicator(color: Colors.cyan))
                  : ListView(
                      padding: EdgeInsets.all(40),
                      children: [
                        // معلومات الحساب
                        _SettingsCard(
                          icon: Icons.person,
                          title: 'معلومات الحساب',
                          subtitle: _username,
                          color: Colors.blue,
                        ),
                        SizedBox(height: 20),
                        
                        // تاريخ الانتهاء
                        _SettingsCard(
                          icon: Icons.calendar_today,
                          title: 'تاريخ انتهاء الاشتراك',
                          subtitle: _expiryDate,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 20),

                        // السيرفر
                        _SettingsCard(
                          icon: Icons.dns,
                          title: 'السيرفر',
                          subtitle: _server,
                          color: Colors.purple,
                        ),
                        SizedBox(height: 30),

                        // اللغات
                        Text(
                          'اختر اللغة / Choose Language',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _LanguageCard(
                              flag: '🇹🇳',
                              name: 'العربية',
                              code: 'AR',
                              selected: _currentLanguage == 'AR',
                              onTap: () => _changeLanguage('AR'),
                            ),
                            _LanguageCard(
                              flag: '🇫🇷',
                              name: 'Français',
                              code: 'FR',
                              selected: _currentLanguage == 'FR',
                              onTap: () => _changeLanguage('FR'),
                            ),
                            _LanguageCard(
                              flag: '🇨🇿',
                              name: 'Čeština',
                              code: 'CZ',
                              selected: _currentLanguage == 'CZ',
                              onTap: () => _changeLanguage('CZ'),
                            ),
                          ],
                        ),
                        SizedBox(height: 40),

                        // WhatsApp
                        _SettingsCard(
                          icon: Icons.whatsapp,
                          title: 'الدعم الفني',
                          subtitle: '+420 777099379',
                          color: Colors.green,
                        ),
                        SizedBox(height: 40),

                        // LOG OUT
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _logout,
                            icon: Icon(Icons.logout, size: 28),
                            label: Text('تسجيل الخروج / LOG OUT', style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
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

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  _SettingsCard({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(height: 5),
                Text(subtitle, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String name;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  _LanguageCard({required this.flag, required this.name, required this.code, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 150,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected? Colors.cyan.withOpacity(0.3) : Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: selected? Colors.cyan : Colors.white24, width: selected? 3 : 1),
          boxShadow: selected? [BoxShadow(color: Colors.cyan, blurRadius: 20)] : [],
        ),
        child: Column(
          children: [
            Text(flag, style: TextStyle(fontSize: 50)),
            SizedBox(height: 10),
            Text(name, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
