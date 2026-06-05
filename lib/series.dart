import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'player.dart';

class SeriesScreen extends StatefulWidget {
  @override
  _SeriesScreenState createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  List series = [];
  List cats = [];
  String sel = 'All';
  bool loading = true;
  String server = '', user = '', pass = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    final p = await SharedPreferences.getInstance();
    server = (p.getString('server')?? '').replaceAll(RegExp(r'/$'), '');
    user = p.getString('username')?? '';
    pass = p.getString('password')?? '';

    try {
      final c = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_series_categories'));
      final s = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_series'));
      if (c.statusCode == 200 && s.statusCode == 200) {
        cats = [{'category_id': 'All', 'category_name': 'الكل'}] + json.decode(c.body);
        series = json.decode(s.body);
        setState(() => loading = false);
      }
    } catch (e) { setState(() => loading = false); }
  }

  List get filtered => sel == 'All'? series : series.where((x) => x['category_id'] == sel).toList();

  _openSeries(dynamic serie) async {
    final id = serie['series_id'];
    showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator(color: Colors.orange)));
    try {
      final res = await http.get(Uri.parse('$server/player_api.php?username=$user&password=$pass&action=get_series_info&series_id=$id'));
      Navigator.pop(context);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        Navigator.push(context, MaterialPageRoute(builder: (_) => EpisodesScreen(name: serie['name'], cover: serie['cover'], episodes: data['episodes'], server: server, user: user, pass: pass)));
      }
    } catch (e) { Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: loading? Center(child: CircularProgressIndicator(color: Colors.orange)) : Column(
        children: [
          Container(padding: EdgeInsets.all(20), child: Row(children: [IconButton(icon: Icon(Icons.arrow_back, color: Colors.white, size: 30), onPressed: ()=>Navigator.pop(context)), Text('SERIES', style: TextStyle(color: Colors.orange, fontSize: 28, fontWeight: FontWeight.bold))])),
          Expanded(child: Row(children: [
            Container(width: 220, color: Colors.black.withOpacity(0.8), child: ListView.builder(itemCount: cats.length, itemBuilder: (_, i){final c=cats[i];final a=c['category_id']==sel;return GestureDetector(onTap:()=>setState(()=>sel=c['category_id']),child:Container(padding:EdgeInsets.all(15),margin:EdgeInsets.all(3),decoration:BoxDecoration(color:a?Colors.orange.withOpacity(0.3):null,border:Border(left:BorderSide(color:a?Colors.orange:Colors.transparent,width:4))),child:Text(c['category_name'],style:TextStyle(color:a?Colors.orange:Colors.white)))));})),
            Expanded(child: GridView.builder(padding:EdgeInsets.all(15),gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:6,childAspectRatio:0.65,crossAxisSpacing:12,mainAxisSpacing:12),itemCount:filtered.length,itemBuilder:(_,i){final s=filtered[i];return GestureDetector(onTap:()=>_openSeries(s),child:Column(children:[Expanded(child:Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(8),color:Colors.grey[900]),child:ClipRRect(borderRadius:BorderRadius.circular(8),child:s['cover']!=null?Image.network(s['cover'],fit:BoxFit.cover,width:double.infinity,errorBuilder:(_,__,___)=>Icon(Icons.tv,size:50)):Icon(Icons.tv,size:50,color:Colors.white30))))),SizedBox(height:6),Text(s['name']??'',maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:Colors.white,fontSize:12),textAlign:TextAlign.center)]));}))
          ]))
        ]
      )
    );
  }
}

class EpisodesScreen extends StatelessWidget {
  final String name; final String? cover; final Map episodes; final String server, user, pass;
  EpisodesScreen({required this.name, this.cover, required this.episodes, required this.server, required this.user, required this.pass});

  @override
  Widget build(BuildContext context) {
    final seasons = episodes.keys.toList()..sort((a,b)=>int.parse(a).compareTo(int.parse(b)));
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: Text(name, style: TextStyle(color: Colors.orange)), iconTheme: IconThemeData(color: Colors.white)),
      body: ListView.builder(
        itemCount: seasons.length,
        itemBuilder: (_, i) {
          final season = seasons[i];
          final eps = episodes[season] as List;
          return ExpansionTile(
            initiallyExpanded: i==0,
            title: Text('الموسم $season', style: TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold)),
            iconColor: Colors.orange,
            collapsedIconColor: Colors.white70,
            children: eps.map((e){
              final ext = e['container_extension']?? 'mp4';
              final url = '$server/series/$user/$pass/${e['id']}.$ext';
              final title = e['title']?? 'الحلقة ${e['episode_num']}';
              return ListTile(
                leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.2), child: Text('${e['episode_num']}', style: TextStyle(color: Colors.orange))),
                title: Text(title, style: TextStyle(color: Colors.white)),
                subtitle: Text('الحلقة ${e['episode_num']}', style: TextStyle(color: Colors.white54)),
                trailing: Icon(Icons.play_circle, color: Colors.orange, size: 30),
                onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>PlayerScreen(url: url, title: title))),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
