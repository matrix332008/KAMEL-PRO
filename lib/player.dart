import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'favorites.dart';

class PlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final String? logo;
  final List? channelList;
  final int? currentIndex;

  PlayerScreen({
    required this.url,
    required this.title,
    this.logo,
    this.channelList,
    this.currentIndex,
  });

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _exo;
  bool _showControls = false;
  bool _showInfo = true;
  bool _showChannelList = false;
  int _listIndex = 0;
  Timer? _hideTimer;
  Timer? _controlsTimer;
  Timer? _updateTimer;
  final ScrollController _channelScroll = ScrollController();
  Map<String, bool> _favs = {};
  DateTime? _okDownTime;

  bool get isLive => widget.channelList!= null;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _listIndex = widget.currentIndex?? 0;
    _initPlayer();
    _showInfoTemporarily();
    _loadFavs();
    _updateTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
      if ((_showControls || _showChannelList) && mounted) setState(() {});
    });
  }

  Future<void> _loadFavs() async {
    if (!isLive) return;
    for (var ch in widget.channelList!) {
      final id = _getId(ch);
      _favs[id] = await Fav.isFav('live', id);
    }
    if (mounted) setState(() {});
  }

  String _getId(Map ch) {
    try {
      return ch['url'].split('/').last.split('.').first;
    } catch (_) {
      return ch['name']?? '';
    }
  }

  Future<void> _toggleFav(int idx) async {
    final ch = widget.channelList![idx];
    final id = _getId(ch);
    bool added = await Fav.toggle('live', {'id': id, 'name': ch['name'], 'logo': ch['logo']});
    setState(() => _favs[id] = added);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(added? 'أضيف للمفضلة' : 'حذف من المفضلة'), duration: Duration(seconds: 1), backgroundColor: Colors.cyan),
    );
  }

  Future<void> _initPlayer() async {
    try {
      _exo = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _exo!.initialize();
      await _exo!.play();
    } catch (e) {
      print('Player error: $e');
    }
    if (mounted) setState(() {});
  }

  void _showInfoTemporarily() {
    setState(() => _showInfo = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: 3), () { if (mounted) setState(() => _showInfo = false); });
  }

  void _showControlsTemporarily() {
    if (isLive) return;
    setState(() => _showControls = true);
    _controlsTimer?.cancel();
    _controlsTimer = Timer(Duration(seconds: 4), () { if (mounted) setState(() => _showControls = false); });
  }

  void _togglePlay() {
    if (_exo == null) return;
    if (_exo!.value.isPlaying) {_exo!.pause();} else {_exo!.play();}
    setState(() {});
  }

  Future<void> _seek(int seconds) async {
    if (_exo == null) return;
    final pos = _exo!.value.position;
    final newPos = pos + Duration(seconds: seconds);
    await _exo!.seekTo(newPos < Duration.zero? Duration.zero : newPos);
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
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlayerScreen(url: next['url'], title: next['name'], logo: next['logo'], channelList: widget.channelList, currentIndex: idx)));
  }

  void _scrollToIndex() {
    if (_channelScroll.hasClients) {
      _channelScroll.animateTo(_listIndex * 56.0, duration: Duration(milliseconds: 150), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _exo?.dispose();
    _hideTimer?.cancel();
    _controlsTimer?.cancel();
    _updateTimer?.cancel();
    _channelScroll.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final dateStr = "${now.day}/${now.month}/${now.year}";
    final channelNum = widget.currentIndex!= null? widget.currentIndex! + 1 : null;

    Duration duration = Duration.zero;
    Duration position = Duration.zero;
    bool isPlaying = false;
    if (_exo!= null && _exo!.value.isInitialized) {
      duration = _exo!.value.duration;
      position = _exo!.value.position;
      isPlaying = _exo!.value.isPlaying;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          final key = event.logicalKey;
          final isOk = key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter;

          if (event is KeyDownEvent && isOk) {
            _okDownTime = DateTime.now();
            return KeyEventResult.handled;
          }

          if (event is KeyUpEvent && isOk) {
            _showInfoTemporarily();
            final dur = _okDownTime!= null? DateTime.now().difference(_okDownTime!).inMilliseconds : 0;
            _okDownTime = null;
            if (isLive && _showChannelList) {
              if (dur > 500) {_toggleFav(_listIndex);} else {_playChannel(_listIndex);}
              return KeyEventResult.handled;
            }
            if (isLive &&!_showChannelList) {
              setState(() {_showChannelList = true; _listIndex = widget.currentIndex?? 0;});
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToIndex());
              return KeyEventResult.handled;
            }
            if (!isLive) {_togglePlay(); _showControlsTemporarily(); return KeyEventResult.handled;}
          }

          if (event is KeyDownEvent) {
            _showInfoTemporarily();
            if (isLive && _showChannelList) {
              if (key == LogicalKeyboardKey.arrowUp) {
                setState(() => _listIndex = (_listIndex - 1 + widget.channelList!.length) % widget.channelList!.length);
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToIndex()); // تم التعديل
              } else if (key == LogicalKeyboardKey.arrowDown) {
                setState(() => _listIndex = (_listIndex + 1) % widget.channelList!.length);
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToIndex()); // تم التعديل
              } else if (key == LogicalKeyboardKey.goBack) {
                setState(() => _showChannelList = false);
                return KeyEventResult.handled;
              }
              return KeyEventResult.handled;
            } else if (isLive) {
              if (key == LogicalKeyboardKey.arrowUp) _nextChannel(-1);
              else if (key == LogicalKeyboardKey.arrowDown) _nextChannel(1);
              else if (key == LogicalKeyboardKey.goBack) return KeyEventResult.ignored;
              return KeyEventResult.handled;
            } else {
              if (key == LogicalKeyboardKey.arrowLeft) {_seek(-10); _showControlsTemporarily();}
              else if (key == LogicalKeyboardKey.arrowRight) {_seek(10); _showControlsTemporarily();}
              else if (key == LogicalKeyboardKey.goBack) {return KeyEventResult.ignored;}
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(children: [
          Positioned.fill(child: _exo!= null && _exo!.value.isInitialized? FittedBox(fit: isLive? BoxFit.fill : BoxFit.contain, child: SizedBox(width: _exo!.value.size.width, height: _exo!.value.size.height, child: VideoPlayer(_exo!))) : Center(child: CircularProgressIndicator(color: Colors.cyan))),
          if (_showInfo) Positioned(top: 30, left: 30, right: 30, child: Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)), child: Row(children: [if (widget.logo!= null) Image.network(widget.logo!, width: 50, height: 50, errorBuilder: (_, __, ___) => SizedBox()), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (channelNum!= null) Text('قناة $channelNum', style: TextStyle(color: Colors.cyan, fontSize: 14)), Text(widget.title, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(timeStr, style: TextStyle(color: Colors.white, fontSize: 18)), Text(dateStr, style: TextStyle(color: Colors.white70))])]))),
          if (!isLive && _showControls) Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: EdgeInsets.fromLTRB(20, 12, 20, 30), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])), child: Column(mainAxisSize: MainAxisSize.min, children: [Slider(value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble() > 0? duration.inSeconds.toDouble() : 1), max: duration.inSeconds.toDouble() > 0? duration.inSeconds.toDouble() : 1, activeColor: Colors.red, inactiveColor: Colors.white30, onChanged: (v) async {await _exo!.seekTo(Duration(seconds: v.toInt()));}), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_formatDuration(position), style: TextStyle(color: Colors.white)), IconButton(iconSize: 48, icon: Icon(isPlaying? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white), onPressed: _togglePlay), Text(_formatDuration(duration), style: TextStyle(color: Colors.white))])]))),
          if (isLive && _showChannelList) Positioned(right: 30, top: 80, bottom: 80, width: 380, child: Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.92), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.cyan, width: 2)), child: Column(children: [Padding(padding: EdgeInsets.all(14), child: Text('القنوات', style: TextStyle(color: Colors.cyan, fontSize: 20, fontWeight: FontWeight.bold))), Expanded(child: ListView.builder(controller: _channelScroll, itemCount: widget.channelList!.length, itemBuilder: (_, i) {final ch = widget.channelList![i]; final active = i == _listIndex; final id = _getId(ch); final isFav = _favs[id] == true; return Container(margin: EdgeInsets.symmetric(horizontal: 8, vertical: 3), padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: active? Colors.cyan : Colors.transparent, borderRadius: BorderRadius.circular(6)), child: Row(children: [SizedBox(width: 28, child: Text('${i + 1}', style: TextStyle(color: active? Colors.black : Colors.white70, fontWeight: FontWeight.bold))), if (ch['logo']!= null) Image.network(ch['logo'], width: 30, height: 30, errorBuilder: (_, __, ___) => Icon(Icons.tv, color: active? Colors.black54 : Colors.white30, size: 24)), SizedBox(width: 10), Expanded(child: Text(ch['name']?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: active? Colors.black : Colors.white, fontSize: 16, fontWeight: active? FontWeight.bold : FontWeight.normal))), Icon(isFav? Icons.favorite : Icons.favorite_border, size: 18, color: isFav? Colors.red : (active? Colors.black54 : Colors.white38))]))}))])]))),
        ]),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }
}
