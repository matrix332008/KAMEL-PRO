import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'player.dart';

class LiveTV extends StatefulWidget { @override _LiveTVState createState() => _LiveTVState(); }
class _LiveTVState extends State<LiveTV> {
  List channels=[]; List groups=[]; String sel='All'; bool loading=true;
  @override void initState(){super.initState();_load();}
  _load() async{
    final p=await SharedPreferences.getInstance();
    String s=(p.getString('server')??'').replaceAll(RegExp(r'/$'),'');
    String u=p.getString('username')??''; String pw=p.getString('password')??'';
    try{
      final c=await http.get(Uri.parse('$s/player_api.php?username=$u&password=$pw&action=get_live_categories')).timeout(Duration(seconds:10));
      final ch=await http.get(Uri.parse('$s/player_api.php?username=$u&password=$pw&action=get_live_streams')).timeout(Duration(seconds:15));
      if(ch.statusCode==200) channels=json.decode(ch.body);
      if(c.statusCode==200){ var cats=json.decode(c.body); groups=[{'category_id':'All','category_name':'الكل'}]; for(var x in cats){ groups.add({'category_id':x['category_id'].toString(),'category_name':x['category_name']}); } }
    }catch(_){}
    if(groups.isEmpty) groups=[{'category_id':'All','category_name':'الكل'}];
    setState(()=>loading=false);
  }
  @override Widget build(BuildContext context){
    final f=sel=='All'?channels:channels.where((e)=>e['category_id'].toString()==sel).toList();
    return Scaffold(backgroundColor:Colors.black,body:loading?Center(child:CircularProgressIndicator(color:Colors.cyan)):Row(children:[
      Container(width:260,color:Colors.black87,child:Column(children:[
        Padding(padding:EdgeInsets.all(12),child:Row(children:[IconButton(icon:Icon(Icons.arrow_back,color:Colors.white),onPressed:()=>Navigator.pop(context)),Text('الباقات',style:TextStyle(color:Colors.cyan,fontSize:20))])),
        Expanded(child:ListView.builder(itemCount:groups.length,itemBuilder:(_,i){final g=groups[i];final a=g['category_id']==sel;return Focus(autofocus:i==0,child:Builder(builder:(ctx){final fo=Focus.of(ctx).hasFocus;return Container(color:fo?Colors.cyan.withOpacity(.2):(a?Colors.cyan.withOpacity(.1):Colors.transparent),child:ListTile(title:Text(g['category_name'],style:TextStyle(color:fo||a?Colors.cyan:Colors.white)),onTap:()=>setState(()=>sel=g['category_id'])));}));}))
      ])),
      Expanded(child:GridView.builder(padding:EdgeInsets.all(16),gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:5,childAspectRatio:2.3,mainAxisSpacing:12,crossAxisSpacing:12),itemCount:f.length,itemBuilder:(_,i){final ch=f[i];return Focus(autofocus:i==0,child:Builder(builder:(ctx){final fo=Focus.of(ctx).hasFocus;return GestureDetector(onTap:()=>_open(ch,f,i),child:AnimatedContainer(duration:Duration(milliseconds:120),alignment:Alignment.center,decoration:BoxDecoration(color:fo?Colors.cyan:Color(0xFF1A1A1A),borderRadius:BorderRadius.circular(8),border:Border.all(color:fo?Colors.white:Colors.white12,width:fo?3:1)),child:Text(ch['name']??'',maxLines:2,textAlign:TextAlign.center,style:TextStyle(color:fo?Colors.black:Colors.white,fontSize:13,fontWeight:fo?FontWeight.bold:FontWeight.normal))));}));}))
    ]));
  }
  _open(ch,f,i) async{final p=await SharedPreferences.getInstance();String s=p.getString('server')??'';String u=p.getString('username')??'';String pw=p.getString('password')??'';String url='$s/live/$u/$pw/${ch['stream_id']}.ts';Navigator.push(context,MaterialPageRoute(builder:(_)=>PlayerScreen(url:url,title:ch['name'],channelList:f.map((e)=>{'name':e['name'],'url':'$s/live/$u/$pw/${e['stream_id']}.ts'}).toList(),currentIndex:i)));}
}
