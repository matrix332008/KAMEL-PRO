import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SpeedTestScreen extends StatefulWidget {
  @override _SpeedTestScreenState createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> with SingleTickerProviderStateMixin {
  double download = 0, upload = 0, current = 0;
  int ping = 0, jitter = 0;
  String status = 'idle', server = 'Auto-detect...', location = '';
  List<String> history = [];
  late AnimationController _needle;

  @override void initState() {
    super.initState();
    _needle = AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    _loadHistory();
    _detectLocation(); // يتعرف على الشبكة أوتوماتيك
  }

  // --- يتعرف على البلد والشبكة ---
  Future<void> _detectLocation() async {
    try {
      final res = await http.get(Uri.parse('http://ip-api.com/json/')).timeout(Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final city = data['city'] ?? '';
        final country = data['country'] ?? '';
        final isp = data['isp'] ?? 'Unknown ISP';
        setState(() {
          location = '$city, $country';
          server = '$isp - $city';
        });
      }
    } catch (_) {
      setState(() {
        server = 'Auto Server';
        location = '';
      });
    }
  }

  _loadHistory() async {
    final p = await SharedPreferences.getInstance();
    setState(() => history = p.getStringList('speed_history') ?? []);
  }

  _saveHistory() async {
    final p = await SharedPreferences.getInstance();
    final entry = '${DateTime.now().day}/${DateTime.now().month} - ${download.toStringAsFixed(1)} Mbps';
    history.insert(0, entry);
    if (history.length > 5) history = history.sublist(0,5);
    await p.setStringList('speed_history', history);
  }

  Future<Map<String,int>> _realPing() async {
    List<int> pings = [];
    for(int i=0;i<5;i++){
      try{
        final sw = Stopwatch()..start();
        final s = await Socket.connect('1.1.1.1', 80, timeout: Duration(seconds: 1));
        s.destroy(); sw.stop(); pings.add(sw.elapsedMilliseconds);
      }catch(_){ pings.add(999); }
      await Future.delayed(Duration(milliseconds: 200));
    }
    pings.sort();
    int avg = pings.reduce((a,b)=>a+b)~/pings.length;
    int jit = (pings.last - pings.first).abs();
    return {'ping':avg, 'jitter':jit};
  }

  Future<double> _testDownload() async {
    final url = 'https://speed.cloudflare.com/__down?bytes=25000000';
    final sw = Stopwatch()..start();
    int bytes = 0;
    try{
      final req = await http.Client().send(http.Request('GET', Uri.parse(url)));
      await for(var chunk in req.stream){
        bytes += chunk.length;
        final elapsed = sw.elapsedMilliseconds/1000;
        if(elapsed>0){
          setState((){
            current = (bytes*8/elapsed/1000000);
            download = current;
            _needle.animateTo(min(current/200,1));
          });
        }
      }
    }catch(_){}
    sw.stop();
    return bytes*8/sw.elapsedMilliseconds/1000;
  }

  Future<double> _testUpload() async {
    final url = 'https://speed.cloudflare.com/__up';
    final data = List.filled(5*1024*1024, 0);
    final sw = Stopwatch()..start();
    try{
      await http.post(Uri.parse(url), body: data);
    }catch(_){}
    sw.stop();
    return data.length*8/sw.elapsedMilliseconds/1000;
  }

  void _start() async {
    setState((){ status='testing'; download=0; upload=0; current=0; });
    final p = await _realPing(); ping=p['ping']!; jitter=p['jitter']!;
    setState((){});
    download = await _testDownload();
    current = 0; _needle.animateTo(0);
    upload = await _testUpload();
    setState((){ status='done'; current=download; _needle.animateTo(min(download/200,1)); });
    _saveHistory();
  }

  String _eval(){
    if(download>=25) return 'ممتاز للـ 4K ✓';
    if(download>=10) return 'جيد للـ HD';
    return 'ضعيف - قد يقطع';
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF070B14),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation:0, centerTitle:true,
        title: Text('SPEEDTEST', style: TextStyle(color: Colors.white30, letterSpacing:2)),
        leading: IconButton(icon:Icon(Icons.close,color:Colors.white54), onPressed:()=>Navigator.pop(context)),
      ),
      body: Column(children:[
        Padding(
          padding:EdgeInsets.only(top:10),
          child: Column(
            children: [
              Text(server, style:TextStyle(color:Colors.white70, fontSize:14)),
              if(location.isNotEmpty) Text(location, style:TextStyle(color:Colors.white38, fontSize:12)),
            ],
          ),
        ),
        if(status!='idle') _cards(),
        Expanded(child: Center(child: status=='idle' ? _go() : _gauge())),
        if(status=='done') _result(),
        if(history.isNotEmpty) _history(),
        SizedBox(height:20),
      ]),
    );
  }

  Widget _go()=>GestureDetector(onTap:_start, child:Container(width:250,height:250,
    decoration:BoxDecoration(shape:BoxShape.circle, border:Border.all(color:Color(0xFF00FF94).withOpacity(0.5),width:12)),
    child:Center(child:Text('GO',style:TextStyle(color:Colors.white,fontSize:64,fontWeight:FontWeight.w200)))));

  Widget _cards()=>Padding(padding:EdgeInsets.all(20), child:Row(children:[
    _card('DOWNLOAD',download,Color(0xFF00FF94)),SizedBox(width:12),
    _card('UPLOAD',upload,Color(0xFF9D4EDD)),
  ]));

  Widget _card(String t,double v,Color c)=>Expanded(child:Container(padding:EdgeInsets.all(18),
    decoration:BoxDecoration(color:Color(0xFF101725),borderRadius:BorderRadius.circular(16),border:Border.all(color:Colors.white12)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(t,style:TextStyle(color:c)), SizedBox(height:10),
      Text(v>0?v.toStringAsFixed(1):'--',style:TextStyle(color:Colors.white,fontSize:32)),
      Text('Mbps',style:TextStyle(color:Colors.white38,fontSize:12)),
    ])));

  Widget _gauge()=>AnimatedBuilder(animation:_needle, builder:(_,__)=>CustomPaint(size:Size(300,300),
    painter:_ProPainter(value:_needle.value, speed:current)));

  Widget _result()=>Column(children:[
    Text(_eval(),style:TextStyle(color:download>=25?Colors.greenAccent:Colors.orange,fontSize:18,fontWeight:FontWeight.bold)),
    SizedBox(height:8),
    Text('Ping $ping ms  •  Jitter $jitter ms',style:TextStyle(color:Colors.white54)),
  ]);

  Widget _history()=>Container(margin:EdgeInsets.symmetric(horizontal:30,vertical:10),padding:EdgeInsets.all(12),
    decoration:BoxDecoration(color:Colors.white5,borderRadius:BorderRadius.circular(12)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('السجل',style:TextStyle(color:Colors.white54,fontSize:12)),
      ...history.map((h)=>Text(h,style:TextStyle(color:Colors.white70,fontSize:13))).toList(),
    ]));

  @override void dispose(){_needle.dispose(); super.dispose();}
}

class _ProPainter extends CustomPainter{
  final double value; final double speed;
  _ProPainter({required this.value, required this.speed});
  @override void paint(Canvas c, Size s){
    final ctr=Offset(s.width/2,s.height/2); final r=s.width*0.42;
    final bg=Paint()..color=Color(0xFF1A2333)..style=PaintingStyle.stroke..strokeWidth=26..strokeCap=StrokeCap.round;
    c.drawArc(Rect.fromCircle(center:ctr,radius:r), 2.35, 4.6, false, bg);
    final fg=Paint()..shader=SweepGradient(colors:[Color(0xFF00FF94),Color(0xFF00C2FF)],startAngle:2.35,endAngle:7).createShader(Rect.fromCircle(center:ctr,radius:r))
      ..style=PaintingStyle.stroke..strokeWidth=26..strokeCap=StrokeCap.round;
    c.drawArc(Rect.fromCircle(center:ctr,radius:r), 2.35, 4.6*value, false, fg);
    final ang=2.35+4.6*value; final end=Offset(ctr.dx+cos(ang)*(r-14), ctr.dy+sin(ang)*(r-14));
    c.drawLine(ctr,end,Paint()..color=Colors.white..strokeWidth=3); c.drawCircle(ctr,5,Paint()..color=Colors.white);
    final tp=TextPainter(text:TextSpan(text:speed.toStringAsFixed(1),style:TextStyle(color:Colors.white,fontSize:52,fontWeight:FontWeight.w200)),textDirection:TextDirection.ltr)..layout();
    tp.paint(c,Offset(ctr.dx-tp.width/2,ctr.dy-18));
  }
  @override bool shouldRepaint(covariant _ProPainter o)=>o.value!=value;
}
