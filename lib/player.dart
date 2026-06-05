import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final List<dynamic>? channelList;
  final int? currentIndex;

  PlayerScreen({required this.url, required this.title, this.channelList, this.currentIndex});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VlcPlayerController? _vlc;
  VideoPlayerController? _exo;
  bool useVlc = true;
  bool _showControls = true;
  bool _showList = false;
  String _num = '';
  int _idx = 0;
  final _focus = FocusNode();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _idx = widget.currentIndex?? 0;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _setup();
    _focus.requestFocus();
  }

  Future<void> _setup() async {
    final p = await SharedPreferences.getInstance();
    useVlc = (p.getString('player')?? 'vlc') == 'vlc';
    await _initPlayer(widget.url);
  }

  Future<void> _initPlayer(String url) async {
    if (url.isEmpty) return;
    setState(() => _ready = false);

    await _vlc?.stop(); await _vlc?.dispose(); _vlc = null;
    await _exo?.pause(); await _exo?.dispose(); _exo = null;

    if (useVlc) {
      _vlc = VlcPlayerController.network(
        url,
        hwAcc: HwAcc.auto,
        autoPlay: true,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([VlcAdvancedOptions.networkCaching(2000)]),
          http: VlcHttpOptions([VlcHttpOptions.httpReconnect(true)]),
        ),
      );
    } else {
      _exo = VideoPlayerController.networkUrl(Uri.parse(url));
      await _exo!.initialize();
      await _exo!.setLooping(true);
      await _exo!.play();
    }
    setState(() => _ready = true);
    _hide();
  }

  void _hide() => Future.delayed(Duration(seconds: 4), () { if(mounted &&!_showList) setState(()=>_showControls=false); });

  Future<void> _play(int i) async {
    if (widget.channelList == null) return;
    final url = widget.channelList![i]['stream_url']?? '';
    setState(() { _idx = i; _showList = false; _showControls = true; });
    await _initPlayer(url);
  }

  void _key(RawKeyEvent e) {
    if (e is! RawKeyDownEvent) return;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.enter) {
      if (_showList) _play(_idx); else setState(()=>_showList =!_showList);
    } else if (k == LogicalKeyboardKey.arrowUp && _showList) {
      setState(()=>_idx = (_idx-1).clamp(0, widget.channelList!.length-1));
    } else if (k == LogicalKeyboardKey.arrowDown && _showList) {
      setState(()=>_idx = (_idx+1).clamp(0, widget.channelList!.length-1));
    } else if (k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.goBack) {
      if (_showList) setState(()=>_showList=false); else Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _vlc?.dispose();
    _exo?.dispose();
    _focus.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.channelList!= null? widget.channelList![_idx]['name']?? widget.title : widget.title;
    Widget video = _ready
     ? (useVlc? VlcPlayer(controller: _vlc!, aspectRatio: 16/9) : AspectRatio(aspectRatio: _exo!.value.aspectRatio, child: VideoPlayer(_exo!)))
      : Center(child: CircularProgressIndicator(color: Colors.cyan));

    return RawKeyboardListener(
      focusNode: _focus, onKey: _key,
      child: Scaffold(backgroundColor: Colors.black,
        body: GestureDetector(onTap: ()=>setState(()=>_showControls=!_showControls),
          child: Stack(children: [
            Center(child: video),
            if (_showControls) Positioned(top:30,left:30,child:Container(padding:EdgeInsets.symmetric(horizontal:20,vertical:10),decoration:BoxDecoration(color:Colors.black54,borderRadius:BorderRadius.circular(10)),child:Text(title,style:TextStyle(color:Colors.white,fontSize:22)))),
            if (_showList && widget.channelList!=null) Positioned(left:0,top:0,bottom:0,child:Container(width:400,color:Colors.black.withOpacity(0.95),child:ListView.builder(itemCount:widget.channelList!.length,itemBuilder:(_,i){final s=i==_idx;return Container(color:s?Colors.cyan.withOpacity(0.3):null,padding:EdgeInsets.all(14),child:Text('${i+1}. ${widget.channelList![i]['name']}',style:TextStyle(color:Colors.white,fontSize:16)));})))
          ])
        )
      )
    );
  }
}
