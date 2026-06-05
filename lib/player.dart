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
  Timer? _controlsTimer;
  Timer? _updateTimer;

  bool get isLive => widget.channelList!= null;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initPlayer();
    _showInfoTemporarily();
    // يحدّث الـ slider كل 500ms
    _updateTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
      if (_showControls && mounted) setState(() {});
    });
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
    _hideTimer = Timer(Duration(seconds: 3), () {
      if (mounted) setState(() => _showInfo = false);
    });
  }

  void _showControlsTemporarily() {
    if (isLive) return;
    setState(() => _showControls = true);
    _controlsTimer?.cancel();
    _controlsTimer = Timer(Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
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

  Future<void> _seek(int seconds) async {
    if (_isVlc && _vlc!= null) {
      final pos = _vlc!.value.position;
      final newPos = pos + Duration(seconds: seconds);
      await _vlc!.seekTo(newPos);
    } else if (!_isVlc && _exo!= null) {
      final pos = _exo!.value.position;
      final newPos = pos + Duration(seconds: seconds);
      await _exo!.seekTo(newPos < Duration.zero? Duration.zero : newPos);
    }
    setState(() {});
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
    _controlsTimer?.cancel();
    _updateTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}";
    final dateStr = "${now.day}/${now.month}/${now.year}";
    final channelNum = widget.currentIndex!= null? widget.currentIndex! + 1 : null;

    Duration duration = Duration.zero;
    Duration position = Duration.zero;
    bool isPlaying = false;
    if (_isVlc && _vlc!= null) {
      duration = _vlc!.value.duration;
      position = _vlc!.value.position;
      isPlaying = _vlc!.value.isPlaying;
    } else if (!_isVlc && _exo!= null && _exo!.value.isInitialized) {
      duration = _exo!.value.duration;
      position = _exo!.value.position;
      isPlaying = _exo!.value.isPlaying;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: RawKeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKey: (e) {
          if (e is RawKeyDownEvent) {
            _showInfoTemporarily();
            if (isLive) {
              // LIVE TV
              if (e.logicalKey == LogicalKeyboardKey.arrowUp) _nextChannel(-1);
              if (e.logicalKey == LogicalKeyboardKey.arrowDown) _nextChannel(1);
              if (e.logicalKey == LogicalKeyboardKey.select || e.logicalKey == LogicalKeyboardKey.enter) {
                Navigator.pop(context);
              }
            } else {
              // FILM / SERIE
              if (e.logicalKey == LogicalKeyboardKey.arrowLeft) { _seek(-10); _showControlsTemporarily(); }
              if (e.logicalKey == LogicalKeyboardKey.arrowRight) { _seek(10); _showControlsTemporarily(); }
              if (e.logicalKey == LogicalKeyboardKey.select || e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
                _togglePlay(); _showControlsTemporarily();
              }
            }
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
            // Info overlay من فوق
            if (_showInfo)
              Positioned(
                top: 30, left: 30, right: 30,
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
            // Controls للفيلم والمسلسل فقط
            if (!isLive && _showControls)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Slider(
                        value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble() > 0? duration.inSeconds.toDouble() : 1),
                        max: duration.inSeconds.toDouble() > 0? duration.inSeconds.toDouble() : 1,
                        activeColor: Colors.red,
                        inactiveColor: Colors.white30,
                        onChanged: (v) async {
                          final newPos = Duration(seconds: v.toInt());
                          if (_isVlc) await _vlc!.seekTo(newPos); else await _exo!.seekTo(newPos);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position), style: TextStyle(color: Colors.white)),
                          IconButton(
                            iconSize: 48,
                            icon: Icon(isPlaying? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white),
                            onPressed: _togglePlay,
                          ),
                          Text(_formatDuration(duration), style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }
}
