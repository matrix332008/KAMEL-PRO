import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class PlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final String? logo;
  final List? channelList;
  final int? currentIndex;

  PlayerScreen({required this.url, required this.title, this.logo, this.channelList, this.currentIndex});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VlcPlayerController? _vlc;
  VideoPlayerController? _exo;
  bool _isVlc = true;
  bool _showControls = false;
  bool _showInfo = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initPlayer();
    _showInfoTemporarily();
  }

  Future<void> _initPlayer() async {
    final p = await SharedPreferences.getInstance();
    _isVlc = (p.getString('player')?? 'vlc') == 'vlc';
    try {
      if (_isVlc) {
        _vlc = VlcPlayerController.network(widget.url, hwAcc: HwAcc.full, autoPlay: true, options: VlcPlayerOptions());
      } else {
        _exo = VideoPlayerController.networkUrl(Uri.parse(widget.url));
        await _exo!.initialize();
        await _exo!.play();
      }
    } catch (e) {}
    setState(() {});
  }

  void _showInfoTemporarily() {
    setState(() => _showInfo = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: 2), () {
      if (mounted) setState(() => _showInfo = false);
    });
  }

  void _togglePlay() {
    if (_isVlc) {
      if (_vlc!.value.isPlaying) _vlc!.pause(); else _vlc!.play();
    } else {
      if (_exo!.value.isPlaying) _exo!.pause(); else _exo!.play();
    }
    setState(() {});
  }

  void _seek(int seconds) {
    if (!_isVlc && _exo!= null) {
      final pos = _exo!.value.position + Duration(seconds: seconds);
      _exo!.seekTo(pos);
    }
  }

  void _nextChannel(int step) {
    if (widget.channelList == null) return;
    int idx = (widget.currentIndex! + step) % widget.channelList!.length;
    if (idx < 0) idx += widget.channelList!.length;
    final next = widget.channelList![idx];
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlayerScreen(
      url: next['url'],
      title: next['name'],
      logo: next['logo'],
      channelList: widget.channelList,
      currentIndex: idx,
    )));
  }

  @override
  void dispose() {
    _vlc?.dispose();
    _exo?.dispose();
    _hideTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}";
    final dateStr = "${now.day}/${now.month}/${now.year}";
    final channelNum = widget.currentIndex!= null? widget.currentIndex! + 1 : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: RawKeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKey: (e) {
          if (e is RawKeyDownEvent) {
            _showInfoTemporarily();
            if (e.logicalKey == LogicalKeyboardKey.arrowUp) _nextChannel(-1);
            if (e.logicalKey == LogicalKeyboardKey.arrowDown) _nextChannel(1);
            if (e.logicalKey == LogicalKeyboardKey.arrowLeft) _seek(-10);
            if (e.logicalKey == LogicalKeyboardKey.arrowRight) _seek(10);
            if (e.logicalKey == LogicalKeyboardKey.select || e.logicalKey == LogicalKeyboardKey.enter) {
              Navigator.pop(context); // OK يرجع للliste
            }
            if (e.logicalKey == LogicalKeyboardKey.mediaPlayPause) _togglePlay();
            if (e.logicalKey == LogicalKeyboardKey.goBack) Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            Center(
              child: _isVlc
                ? (_vlc!= null? VlcPlayer(controller: _vlc!, aspectRatio: 16/9) : CircularProgressIndicator())
                  : (_exo!= null && _exo!.value.isInitialized? AspectRatio(aspectRatio: _exo!.value.aspectRatio, child: VideoPlayer(_exo!)) : CircularProgressIndicator()),
            ),
            // Info overlay
            if (_showInfo)
              Positioned(
                top: 30,
                left: 30,
                right: 30,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      if (widget.logo!= null) Image.network(widget.logo!, width: 50, height: 50, errorBuilder: (_,__,___) => SizedBox()),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (channelNum!= null) Text('قناة $channelNum', style: TextStyle(color: Colors.cyan, fontSize: 14)),
                            Text(widget.title, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(timeStr, style: TextStyle(color: Colors.white, fontSize: 18)),
                          Text(dateStr, style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            // Play/Pause button (يظهر كي تضغط OK مرتين)
            if (_showControls)
              Center(
                child: IconButton(
                  iconSize: 80,
                  icon: Icon(_isVlc? (_vlc?.value.isPlaying == true? Icons.pause : Icons.play_arrow) : (_exo?.value.isPlaying == true? Icons.pause : Icons.play_arrow), color: Colors.white70),
                  onPressed: _togglePlay,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
