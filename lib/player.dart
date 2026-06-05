import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final List? channelList;
  final int? currentIndex;

  PlayerScreen({required this.url, required this.title, this.channelList, this.currentIndex});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VlcPlayerController? _vlc;
  VideoPlayerController? _exo;
  bool _isVlc = true;
  bool _error = false;
  String _errMsg = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _init();
  }

  _init() async {
    final p = await SharedPreferences.getInstance();
    _isVlc = (p.getString('player')?? 'vlc') == 'vlc';

    try {
      if (_isVlc) {
        _vlc = VlcPlayerController.network(
          widget.url,
          hwAcc: HwAcc.full,
          autoPlay: true,
          options: VlcPlayerOptions(
            advanced: VlcAdvancedOptions([VlcAdvancedOptions.networkCaching(2000)]),
            http: VlcHttpOptions([VlcHttpOptions.reconnect(true)]),
          ),
        );
        _vlc!.addListener(() {
          if (_vlc!.value.hasError && mounted) {
            setState(() {
              _error = true;
              _errMsg = 'VLC لا يقرأ الرابط';
            });
          }
        });
      } else {
        _exo = VideoPlayerController.networkUrl(Uri.parse(widget.url));
        await _exo!.initialize();
        await _exo!.play();
        _exo!.addListener(() {
          if (_exo!.value.hasError && mounted) {
            setState(() {
              _error = true;
              _errMsg = 'EXO لا يقرأ الرابط';
            });
          }
        });
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() {
        _error = true;
        _errMsg = 'خطأ: $e';
      });
    }
  }

  @override
  void dispose() {
    _vlc?.dispose();
    _exo?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _next(int step) {
    if (widget.channelList == null) return;
    int idx = (widget.currentIndex! + step) % widget.channelList!.length;
    if (idx < 0) idx += widget.channelList!.length;
    final next = widget.channelList![idx];
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => PlayerScreen(url: next['stream_url'], title: next['name'], channelList: widget.channelList, currentIndex: idx),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RawKeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKey: (e) {
          if (e is RawKeyDownEvent) {
            if (e.logicalKey == LogicalKeyboardKey.arrowUp) _next(1);
            if (e.logicalKey == LogicalKeyboardKey.arrowDown) _next(-1);
            if (e.logicalKey == LogicalKeyboardKey.goBack || e.logicalKey == LogicalKeyboardKey.escape) Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            Center(
              child: _error
                 ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.error, color: Colors.red, size: 80),
                      SizedBox(height: 20),
                      Text(_errMsg, style: TextStyle(color: Colors.white, fontSize: 20)),
                      SizedBox(height: 10),
                      Text('جرب بدل المشغل من AJUSTES', style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 30),
                      ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('رجوع')),
                    ])
                  : _isVlc
                     ? (_vlc!= null? VlcPlayer(controller: _vlc!, aspectRatio: 16 / 9, placeholder: Center(child: CircularProgressIndicator())) : CircularProgressIndicator())
                      : (_exo!= null && _exo!.value.isInitialized? AspectRatio(aspectRatio: _exo!.value.aspectRatio, child: VideoPlayer(_exo!)) : CircularProgressIndicator()),
            ),
            Positioned(top: 30, left: 20, child: Container(padding: EdgeInsets.all(10), color: Colors.black54, child: Text(widget.title, style: TextStyle(color: Colors.white, fontSize: 18)))),
          ],
        ),
      ),
    );
  }
}
