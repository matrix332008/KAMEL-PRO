import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'favorites.dart';
import 'lang.dart';

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
  VideoPlayerController? _exo;
  bool _showControls = false;
  bool _showInfo = true;
  bool _showChannelList = false;
  int _listIndex = 0;
  Timer? _hideTimer;
  Timer? _controlsTimer;
  Timer? _saveTimer;
  final ScrollController _channelScroll = ScrollController();
  final FavoritesService _favService = FavoritesService();
  Set<String> _favIds = {};

  late String _currentUrl;
  late String _currentTitle;
  String? _currentLogo;
  late int _currentIndex;

  String _deviceMac = '';
  bool _isFavCloud = false;

  // Supabase
  final String supaUrl = 'https://pmgdzroirlegkpqzcyra.supabase.co';
  final String supaKey = 'sb_publishable_gkeT9X4EbhXj3Rb2HoKNag_pj7JpdFj';

  bool get isLive => widget.channelList!= null;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _currentUrl = widget.url;
    _currentTitle = widget.title;
    _currentLogo = widget.logo;
    _currentIndex = widget.currentIndex?? 0;
    _listIndex = _currentIndex;
    _loadMac().then((_) {
      _initPlayer();
      if (!isLive) _checkResume();
      _checkFavorite();
    });
    _showInfoTemporarily();
    _favService.getFavoriteUrls().then((set) {
      if (mounted) setState(() => _favIds = set);
    });
  }

  Future<void> _loadMac() async {
    final p = await SharedPreferences.getInstance();
    _deviceMac = p.getString('device_mac')?? '';
  }

  Future<void> _initPlayer() async {
    await _exo?.dispose();
    try {
      _exo = VideoPlayerController.networkUrl(Uri.parse(_currentUrl));
      await _exo!.initialize();
      await _exo!.play();
      _exo!.addListener(() { if (mounted) setState(() {}); });
      if (!isLive) _startSaveTimer();
    } catch (e) {
      print('Player error: $e');
    }
    if (mounted) setState(() {});
  }

  // === متابعة المشاهدة ===
  Future<void> _checkResume() async {
    if (_deviceMac.isEmpty) return;
    try {
      final res = await http.get(
        Uri.parse('$supaUrl/rest/v1/watch_progress?mac=eq.$_deviceMac&stream_url=eq.${Uri.encodeComponent(_currentUrl)}&select=position'),
        headers: {'apikey': supaKey, 'Authorization': 'Bearer $supaKey'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data.isNotEmpty) {
          final pos = data[0]['position']?? 0;
          if (pos > 15) {
            await Future.delayed(Duration(milliseconds: 500));
            _showResumeDialog(pos);
          }
        }
      }
    } catch (e) {}
  }

  void _showResumeDialog(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text('متابعة المشاهدة', style: TextStyle(color: Colors.white)),
        content: Text('تحب تكمل من $m:$s ؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('من الأول', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _exo?.seekTo(Duration(seconds: seconds));
            },
            child: Text('متابعة'),
          ),
        ],
      ),
    );
  }

  void _startSaveTimer() {
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(Duration(seconds: 5), (_) => _saveProgress());
  }

  Future<void> _saveProgress() async {
    if (_exo == null ||!_exo!.value.isInitialized || isLive || _deviceMac.isEmpty) return;
    final pos = _exo!.value.position.inSeconds;
    final dur = _exo!.value.duration.inSeconds;
    if (pos < 5) return;

    try {
      await http.post(
        Uri.parse('$supaUrl/rest/v1/watch_progress?on_conflict=mac,stream_url'),
        headers: {
          'apikey': supaKey,
          'Authorization': 'Bearer $supaKey',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates'
        },
        body: json.encode({
          'mac': _deviceMac,
          'stream_url': _currentUrl,
          'title': _currentTitle,
          'position': pos,
          'duration': dur,
          'updated_at': DateTime.now().toIso8601String(),
          'type': 'vod'
        }),
      );
    } catch (e) {}
  }

  // === المفضلة السحابية ===
  Future<void> _checkFavorite() async {
    if (_deviceMac.isEmpty || isLive) return;
    try {
      final res = await http.get(
        Uri.parse('$supaUrl/rest/v1/favorites?mac=eq.$_deviceMac&stream_url=eq.${Uri.encodeComponent(_currentUrl)}&select=id'),
        headers: {'apikey': supaKey, 'Authorization': 'Bearer $supaKey'},
      );
      if (res.statusCode == 200 && json.decode(res.body).isNotEmpty) {
        setState(() => _isFavCloud = true);
      }
    } catch (e) {}
  }

  Future<void> _toggleFavCloud() async {
    if (_deviceMac.isEmpty) return;
    setState(() => _isFavCloud =!_isFavCloud);
    try {
      if (_isFavCloud) {
        await http.post(
          Uri.parse('$supaUrl/rest/v1/favorites'),
          headers: {'apikey': supaKey, 'Authorization': 'Bearer $supaKey', 'Content-Type': 'application/json'},
          body: json.encode({
            'mac': _deviceMac,
            'stream_url': _currentUrl,
            'title': _currentTitle,
            'logo': _currentLogo?? '',
            'type': isLive? 'live' : 'vod'
          }),
        );
      } else {
        await http.delete(
          Uri.parse('$supaUrl/rest/v1/favorites?mac=eq.$_deviceMac&stream_url=eq.${Uri.encodeComponent(_currentUrl)}'),
          headers: {'apikey': supaKey, 'Authorization': 'Bearer $supaKey'},
        );
      }
    } catch (e) {}
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
    if (_exo == null) return;
    if (_exo!.value.isPlaying) _exo!.pause(); else _exo!.play();
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
    int idx = (_currentIndex + step) % widget.channelList!.length;
    if (idx < 0) idx += widget.channelList!.length;
    _playChannel(idx);
  }

  void _playChannel(int idx) {
    final next = widget.channelList![idx];
    setState(() {
      _currentUrl = next['url'];
      _currentTitle = next['name'];
      _currentLogo = next['logo'];
      _currentIndex = idx;
      _listIndex = idx;
      _showChannelList = false;
    });
    _initPlayer();
    _showInfoTemporarily();
  }

  void _toggleFavorite(int idx) {
    final ch = widget.channelList![idx];
    final name = ch['name']?? '';
    final url = ch['url']?? '';
    final logo = ch['logo']?? '';
    _favService.toggle(name, url, logo);
    setState(() {
      if (_favIds.contains(url)) _favIds.remove(url); else _favIds.add(url);
    });
  }

  void _scrollToIndex() {
    if (_channelScroll.hasClients) {
      _channelScroll.animateTo(_listIndex * 56.0, duration: Duration(milliseconds: 150), curve: Curves.easeOut);
    }
  }

  String _fmt(Duration d) => "${d.inMinutes.remainder(60).toString().padLeft(2,'0')}:${(d.inSeconds.remainder(60)).toString().padLeft(2,'0')}";

  @override
  void dispose() {
    _saveProgress();
    _exo?.dispose();
    _hideTimer?.cancel();
    _controlsTimer?.cancel();
    _saveTimer?.cancel();
    _channelScroll.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}";
    final dateStr = "${now.day}/${now.month}/${now.year}";
    final channelNum = isLive? _currentIndex + 1 : null;

    return WillPopScope(
      onWillPop: () async {
        if (_showChannelList) {
          setState(() => _showChannelList = false);
          _showInfoTemporarily();
          return false;
        }
        if (_showControls) {
          setState(() => _showControls = false);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              final key = event.logicalKey;
              if (!_showChannelList) _showInfoTemporarily();

              if (isLive) {
                if (_showChannelList) {
                  if (key == LogicalKeyboardKey.arrowUp) {
                    setState(() => _listIndex = (_listIndex - 1 + widget.channelList!.length) % widget.channelList!.length);
                    _scrollToIndex();
                  } else if (key == LogicalKeyboardKey.arrowDown) {
                    setState(() => _listIndex = (_listIndex + 1) % widget.channelList!.length);
                    _scrollToIndex();
                  } else if (key == LogicalKeyboardKey.arrowRight) {
                    _toggleFavorite(_listIndex);
                  } else if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
                    _playChannel(_listIndex);
                  } else if (key == LogicalKeyboardKey.goBack || key == LogicalKeyboardKey.escape) {
                    return KeyEventResult.ignored;
                  }
                  return KeyEventResult.handled;
                } else {
                  if (key == LogicalKeyboardKey.arrowUp) _nextChannel(-1);
                  else if (key == LogicalKeyboardKey.arrowDown) _nextChannel(1);
                  else if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
                    setState(() {
                      _showChannelList = true;
                      _listIndex = _currentIndex;
                      _showInfo = false;
                      _hideTimer?.cancel();
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToIndex());
                  } else if (key == LogicalKeyboardKey.goBack || key == LogicalKeyboardKey.escape) {
                    return KeyEventResult.ignored;
                  }
                  return KeyEventResult.handled;
                }
              } else {
                if (key == LogicalKeyboardKey.arrowLeft) { _seek(-10); _showControlsTemporarily(); }
                else if (key == LogicalKeyboardKey.arrowRight) { _seek(10); _showControlsTemporarily(); }
                else if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.mediaPlayPause) {
                  _togglePlay(); _showControlsTemporarily();
                } else if (key == LogicalKeyboardKey.goBack || key == LogicalKeyboardKey.escape) {
                  return KeyEventResult.ignored;
                }
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: _exo!= null && _exo!.value.isInitialized
                   ? FittedBox(
                        fit: BoxFit.fill,
                        child: SizedBox(
                          width: _exo!.value.size.width,
                          height: _exo!.value.size.height,
                          child: VideoPlayer(_exo!),
                        ),
                      )
                    : Center(child: CircularProgressIndicator(color: Colors.cyan)),
              ),
              if (_showInfo)
                Positioned(
                  top: 30, left: 30, right: 30,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        if (_currentLogo!= null) Image.network(_currentLogo!, width: 50, height: 50, errorBuilder: (_, __, ___) => SizedBox()),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (channelNum!= null) Text('${Lang.get('channel')} $channelNum', style: TextStyle(color: Colors.cyan, fontSize: 14)),
                              Text(_currentTitle, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        if (!isLive) IconButton(
                          icon: Icon(_isFavCloud? Icons.favorite : Icons.favorite_border, color: _isFavCloud? Colors.red : Colors.white, size: 28),
                          onPressed: _toggleFavCloud,
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
              if (!isLive && _showControls && _exo!= null && _exo!.value.isInitialized)
                Positioned(
                  bottom: 40, left: 40, right: 40,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(_exo!, allowScrubbing: true, colors: VideoProgressColors(playedColor: Colors.cyan, bufferedColor: Colors.white24, backgroundColor: Colors.white10)),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(icon: Icon(_exo!.value.isPlaying? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32), onPressed: _togglePlay),
                            SizedBox(width: 8),
                            Text(_fmt(_exo!.value.position), style: TextStyle(color: Colors.white)),
                            Spacer(),
                            Text(_fmt(_exo!.value.duration), style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (isLive && _showChannelList)
                Positioned(
                  right: 30, top: 80, bottom: 80, width: 380,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.92), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.cyan, width: 2)),
                    child: Column(
                      children: [
                        Padding(padding: EdgeInsets.all(14), child: Text(Lang.get('channels'), style: TextStyle(color: Colors.cyan, fontSize: 20, fontWeight: FontWeight.bold))),
                        Expanded(
                          child: ListView.builder(
                            controller: _channelScroll,
                            itemCount: widget.channelList!.length,
                            itemBuilder: (_, i) {
                              final ch = widget.channelList![i];
                              final active = i == _listIndex;
                              final url = ch['url']?? '';
                              final isFav = _favIds.contains(url);
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
                                    if (ch['logo']!= null) Image.network(ch['logo'], width: 30, height: 30, errorBuilder: (_, __, ___) => Icon(Icons.tv, color: active? Colors.black54 : Colors.white30, size: 24)),
                                    SizedBox(width: 10),
                                    Expanded(child: Text(ch['name']?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: active? Colors.black : Colors.white, fontSize: 16, fontWeight: active? FontWeight.bold : FontWeight.normal))),
                                    if (isFav) Image.asset('assets/favorites.png', width: 22, height: 22, color: Colors.red) else Icon(Icons.favorite_border, color: Colors.white24, size: 20),
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
      ),
    );
  }
}
