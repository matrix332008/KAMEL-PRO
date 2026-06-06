import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
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

  bool get isLive => widget.channelList != null;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _listIndex = widget.currentIndex ?? 0;
    _initPlayer();
    _showInfoTemporarily();
    _updateTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
      if ((_showControls || _showChannelList) && mounted) setState(() {});
    });
  }

  Future<void> _initPlayer() async {
    final p = await SharedPreferences.getInstance();
    _isVlc = isLive ? false : (p.getString('player') ?? 'vlc') == 'vlc';
    try {
      if (_isVlc) {
        _vlc = VlcPlayerController.network(widget.url, hwAcc: HwAcc.auto, autoPlay: true, options: VlcPlayerOptions());
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

  // ... باقي الدوال كيما عندك

  @override
  Widget build(BuildContext context) {
    // ... نفس الكود
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) { /* نفس الكود */ return KeyEventResult.ignored; },
        child: Stack(
          children: [
            Positioned.fill(
              child: _isVlc
                  ? (_vlc != null
                      ? FittedBox(
                          fit: isLive ? BoxFit.fill : BoxFit.contain, // <--- هنا التغيير
                          child: SizedBox(width: 1920, height: 1080, child: VlcPlayer(controller: _vlc!, aspectRatio: 16 / 9)),
                        )
                      : Center(child: CircularProgressIndicator()))
                  : (_exo != null && _exo!.value.isInitialized
                      ? FittedBox(
                          fit: isLive ? BoxFit.fill : BoxFit.contain, // <--- وهنا
                          child: SizedBox(
                            width: _exo!.value.size.width,
                            height: _exo!.value.size.height,
                            child: VideoPlayer(_exo!),
                          ),
                        )
                      : Center(child: CircularProgressIndicator())),
            ),
            // باقي الواجهة...
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    _vlc?.dispose();
    _exo?.dispose();
    _hideTimer?.cancel();
    _controlsTimer?.cancel();
    _updateTimer?.cancel();
    _channelScroll.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
