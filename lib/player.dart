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
  bool _showChannelList = false;
  int _listIndex = 0;
  Timer? _hideTimer;
  Timer? _controlsTimer;
  Timer? _updateTimer;
  final ScrollController _channelScroll = ScrollController();

  bool get isLive => widget.channelList!= null;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _listIndex = widget.currentIndex?? 0;
    _initPlayer();
    _showInfoTemporarily();
    _updateTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
      if ((_showControls || _showChannelList) && mounted) setState(() {});
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
      await _vlc!.seekTo(pos + Duration(seconds: seconds));
    } else if (!_isVlc && _exo!= null) {
      final pos = _exo!.value.position;
      final newPos = pos + Duration(seconds: seconds);
      await _exo!.seekTo(newPos < Duration.zero? Duration.zero : newPos);
    }
    setState(() {});
  }

  void _nextChannel(int step) {
    if (!isLive) return;
    int idx = (widget.currentIndex! + step) % widget.channelList!.length;
    if (idx < 0) idx += widget.channelList!.length;
    _playChannel(idx);
  }

  void _playChannel(int idx) {
    final next = widget.channelList![idx];
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlayerScreen(
      url: next['url'],
      title: next['name'],
      logo: next['logo'],
      channelList: widget.channelList,
      currentIndex: idx,
    )));
  }

  void _scrollToIndex() {
    if (_channelScroll.hasClients) {
      _channelScroll.animateTo(_listIndex * 56.0, duration: Duration(milliseconds: 150), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _vlc?.dispose();
    _exo?.dispose();
    _hideTimer?.cancel();
    _controlsTimer?.cancel();
    _updateTimer?.cancel();
    _channelScroll.dispose();
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
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            _showInfoTemporarily();
            final key = event.logicalKey;

            if (isLive) {
              if (_showChannelList) {
                if (key == LogicalKeyboardKey.arrowUp) {
                  setState(() => _listIndex = (_listIndex - 1 + widget.channelList!.length) % widget.channelList!.length);
                  _scrollToIndex();
                } else if (key == LogicalKeyboardKey.arrowDown) {
                  setState(() => _listIndex = (_listIndex + 1) % widget.channelList!.length);
                  _scrollToIndex();
                } else if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
                  _playChannel(_listIndex);
                } else if (key == LogicalKeyboardKey.goBack) {
                  setState(() => _showChannelList = false);
                }
                return KeyEventResult.handled;
              } else {
                if (key == LogicalKeyboardKey.arrowUp) _nextChannel(-1);
                else if (key == LogicalKeyboardKey.arrowDown) _nextChannel(1);
                else if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
                  setState(() { _showChannelList = true; _listIndex = widget.currentIndex?? 0; });
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToIndex());
                } else if (key == LogicalKeyboardKey.goBack) {
                  Navigator.maybePop(context);
                }
                return KeyEventResult.handled;
              }
            } else {
              // VOD
              if (key == LogicalKeyboardKey.arrowLeft) { _seek(-10); _showControlsTemporarily(); }
              else if (key == LogicalKeyboardKey.arrowRight) { _seek(10); _showControlsTemporarily(); }
              else if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.mediaPlayPause) {
                _togglePlay(); _showControlsTemporarily();
              } else if (key == LogicalKeyboardKey.goBack) {
                Navigator.maybePop(context);
              }
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // فيديو يملأ الشاشة بلا باندة
            Positioned.fill(
              child: _isVlc
                 ? (_vlc!= null
                     ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(width: 1920, height: 1080, child: VlcPlayer(controller: _vlc!, aspectRatio: 16/9)),
                        )
                      : Center(child: CircularProgressIndicator()))
                  : (_exo!= null && _exo!.value.isInitialized
                     ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _exo!.value.size.width,
                            height: _exo!.value.size.height,
                            child: VideoPlayer(_exo!),
                          ),
                        )
                      : Center(child: CircularProgressIndicator())),
            ),
            // Info من فوق
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
            // Controls VOD
            if (!isLive && _showControls)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 30),
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])),
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
                          IconButton(iconSize: 48, icon: Icon(isPlaying? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white), onPressed: _togglePlay),
                          Text(_formatDuration(duration), style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            // لستة القنوات أوضح
            if (isLive && _showChannelList)
              Positioned(
                right: 30, top: 80, bottom: 80, width: 380,
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.92), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.cyan, width: 2)),
                  child: Column(
                    children: [
                      Padding(padding: EdgeInsets.all(14), child: Text('القنوات', style: TextStyle(color: Colors.cyan, fontSize: 20, fontWeight: FontWeight.bold))),
                      Expanded(
                        child: ListView.builder(
                          controller: _channelScroll,
                          itemCount: widget.channelList!.length,
                          itemBuilder: (_, i) {
                            final ch = widget.channelList![i];
                            final active = i == _listIndex;
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: active? Colors.cyan : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 28, child: Text('${i + 1}', style: TextStyle(color: active? Colors.black : Colors.white70, fontWeight: FontWeight.bold))),
                                  if (ch['logo']!= null) Image.network(ch['logo'], width: 30, height: 30, errorBuilder: (_,__,___) => Icon(Icons.tv, color: active? Colors.black54 : Colors.white30, size: 24)),
                                  SizedBox(width: 10),
                                  Expanded(child: Text(ch['name']?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: active? Colors.black : Colors.white, fontSize: 16, fontWeight: active? FontWeight.bold : FontWeight.normal))),
                                ],
                              ),
                            );
                          },
                        ),
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
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }
}
