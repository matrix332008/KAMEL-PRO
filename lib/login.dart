import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart'; // باش نرجعو للـ MainMenu

class LoginSelection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                    Image.asset('assets/logo.png', width: 200),
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
        ],
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  final String title; final IconData icon; final Color color; final VoidCallback onTap; final bool autofocus;
  _LoginCard({required this.title, required this.icon, required this.color, required this.onTap, this.autofocus = false});
  @override __LoginCardState createState() => __LoginCardState();
}
class __LoginCardState extends State<_LoginCard> {
  bool _focused = false;
  @override Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (h) => setState(() => _focused = h),
      onKeyEvent: (n,e){ if(e is KeyDownEvent && (e.logicalKey==LogicalKeyboardKey.select||e.logicalKey==LogicalKeyboardKey.enter)){widget.onTap();return KeyEventResult.handled;} return KeyEventResult.ignored;},
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 280, height: 200,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _focused? widget.color : widget.color.withOpacity(0.5), width: _focused?4:2),
            boxShadow: _focused?[BoxShadow(color: widget.color, blurRadius: 30, spreadRadius: 5)]:[],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
            Icon(widget.icon, size: 60, color: widget.color),
            SizedBox(height:20),
            Text(widget.title, style: TextStyle(color: Colors.white, fontSize:22, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}

// ============= XTREAM =============
class XtreamLogin extends StatefulWidget { @override _XtreamLoginState createState()=>_XtreamLoginState();}
class _XtreamLoginState extends State<XtreamLogin> {
  final _server=TextEditingController(); final _user=TextEditingController(); final _pass=TextEditingController();
  bool _loading=false; final _s=FocusNode(); final _u=FocusNode(); final _p=FocusNode();
  @override void initState(){super.initState(); _s.requestFocus();}
  @override void dispose(){_s.dispose();_u.dispose();_p.dispose();super.dispose();}
  _login() async{
    setState(()=>_loading=true);
    String server=_server.text.trim().replaceAll(RegExp(r'/player_api\.php.*$',caseSensitive:false),'').replaceAll(RegExp(r'/$'),'');
    String user=_user.text.trim(); String pass=_pass.text.trim();
    if(server.isEmpty||user.isEmpty||pass.isEmpty){_err('Please fill all fields');setState(()=>_loading=false);return;}
    try{
      final res=await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass')).timeout(Duration(seconds:10));
      if(res.statusCode==200){var d=json.decode(res.body); if(d['user_info']['auth']==1){
        final p=await SharedPreferences.getInstance();
        await p.setBool('isLoggedIn',true); await p.setString('loginType','xtream');
        await p.setString('server',server); await p.setString('username',user); await p.setString('password',pass);
        await p.setString('xtreamData',res.body);
        Navigator.pushReplacement(context, MaterialPageRoute(builder:(_)=>MainMenu()));
      }else{_err('Invalid credentials');}}else{_err('Server error');}
    }catch(e){_err('Connection failed');}
    setState(()=>_loading=false);
  }
  _err(m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m),backgroundColor:Colors.red));
  @override Widget build(BuildContext context){
    return Scaffold(
      body: Stack(fit: StackFit.expand, children:[
        Image.asset('assets/background.jpeg', fit: BoxFit.fill),
        Center(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width*0.45,
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
              child: Column(children:[
                Image.asset('assets/logo.png', width:180),
                SizedBox(height:30),
                _Input(controller:_server,hint:'SERVER URL',color:Colors.cyan,focus:_s,next:_u),
                SizedBox(height:20),
                _Input(controller:_user,hint:'USERNAME',color:Colors.cyan,focus:_u,next:_p),
                SizedBox(height:20),
                _Input(controller:_pass,hint:'PASSWORD',color:Colors.cyan,obscure:true,focus:_p,action:TextInputAction.done,submit:(_)=>_login()),
                SizedBox(height:30),
                Row(mainAxisAlignment:MainAxisAlignment.center,children:[
                  _Btn(text:'LOGIN',color:Colors.cyan,onTap:_loading?null:_login),
                  SizedBox(width:20),
                  _Btn(text:'CANCEL',color:Colors.grey,onTap:()=>Navigator.pop(context)),
                ])
              ]),
            ),
          ),
        )
      ]),
    );
  }
}

// ============= M3U =============
class M3ULogin extends StatefulWidget { @override _M3ULoginState createState()=>_M3ULoginState();}
class _M3ULoginState extends State<M3ULogin> {
  final _url=TextEditingController(); final _name=TextEditingController(); bool _loading=false; final _u=FocusNode(); final _n=FocusNode();
  @override void initState(){super.initState();_u.requestFocus();}
  _login() async{setState(()=>_loading=true); String url=_url.text.trim(); if(url.isEmpty){_err('Please enter M3U URL');setState(()=>_loading=false);return;}
    final p=await SharedPreferences.getInstance(); await p.setBool('isLoggedIn',true); await p.setString('loginType','m3u');
    await p.setString('m3uUrl',url); await p.setString('playlistName',_name.text.trim());
    Navigator.pushReplacement(context, MaterialPageRoute(builder:(_)=>MainMenu()));
  }
  _err(m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m),backgroundColor:Colors.red));
  @override Widget build(BuildContext context){
    return Scaffold(
      body: Stack(fit: StackFit.expand, children:[
        Image.asset('assets/background.jpeg', fit: BoxFit.fill),
        Center(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width*0.45,
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
              child: Column(children:[
                Image.asset('assets/logo.png', width:180),
                SizedBox(height:30),
                _Input(controller:_url,hint:'M3U URL',color:Colors.red,focus:_u,next:_n),
                SizedBox(height:20),
                _Input(controller:_name,hint:'PLAYLIST NAME (Optional)',color:Colors.red,focus:_n,action:TextInputAction.done,submit:(_)=>_login()),
                SizedBox(height:30),
                Row(mainAxisAlignment:MainAxisAlignment.center,children:[
                  _Btn(text:'LOGIN',color:Colors.red,onTap:_loading?null:_login),
                  SizedBox(width:20),
                  _Btn(text:'CANCEL',color:Colors.grey,onTap:()=>Navigator.pop(context)),
                ])
              ]),
            ),
          ),
        )
      ]),
    );
  }
}

class _Input extends StatefulWidget{
  final TextEditingController controller; final String hint; final Color color; final bool obscure; final FocusNode? focus; final FocusNode? next; final TextInputAction? action; final Function(String)? submit;
  _Input({required this.controller,required this.hint,required this.color,this.obscure=false,this.focus,this.next,this.action,this.submit});
  @override __InputState createState()=>__InputState();
}
class __InputState extends State<_Input>{bool f=false;@override Widget build(BuildContext context){return Focus(onFocusChange:(h)=>setState(()=>f=h),child:TextField(controller:widget.controller,obscureText:widget.obscure,focusNode:widget.focus,textInputAction:widget.action??TextInputAction.next,onSubmitted:(v){if(widget.submit!=null)widget.submit!(v);else if(widget.next!=null)widget.next!.requestFocus();},style:TextStyle(color:Colors.white),decoration:InputDecoration(hintText:widget.hint,hintStyle:TextStyle(color:Colors.white54),filled:true,fillColor:Colors.black.withOpacity(0.5),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(15),borderSide:BorderSide(color:widget.color,width:2)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(15),borderSide:BorderSide(color:widget.color,width:3)),)));}}

class _Btn extends StatefulWidget{final String text;final Color color;final VoidCallback? onTap;_Btn({required this.text,required this.color,this.onTap});@override __BtnState createState()=>__BtnState();}
class __BtnState extends State<_Btn>{bool f=false;@override Widget build(BuildContext context){return Focus(onFocusChange:(h)=>setState(()=>f=h),onKeyEvent:(n,e){if(e is KeyDownEvent && (e.logicalKey==LogicalKeyboardKey.select||e.logicalKey==LogicalKeyboardKey.enter)){if(widget.onTap!=null)widget.onTap!();return KeyEventResult.handled;}return KeyEventResult.ignored;},child:Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(15),border:Border.all(color:f?widget.color:Colors.transparent,width:3)),child:ElevatedButton(onPressed:widget.onTap,style:ElevatedButton.styleFrom(backgroundColor:widget.color,padding:EdgeInsets.symmetric(horizontal:40,vertical:15),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15))),child:Text(widget.text,style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)))));}}
