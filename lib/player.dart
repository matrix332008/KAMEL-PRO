import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'favorites.dart';

class PlayerScreen extends StatefulWidget {
  final String url;
  final String? title;
  final String? logo;
  final List? channelList;
  final int? currentIndex;

  const PlayerScreen({
    required this.url,
    this.title,
    this.logo,
    this.channelList,
    this.currentIndex,
    super.key,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _vc;
  ChewieController? _chewie;
  bool isLive = false;
  bool _showList = false;
  int _idx = 0;
  Map<String, bool> _favs = {};
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    isLive = widget.url.contains('/live/');
    _idx = widget.currentIndex?? 0;
    _init();
  }

  Future<void> _init() async {
    _vc = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await _vc.initialize();

    if (!isLive) {
      _chewie = ChewieController(
        videoPlayerController: _vc,
        autoPlay: true,
        showControls: true,
        showControlsOnInitialize: true,
      );
    } else {
      await _vc.setLooping(true);
      await _vc.play();
      _loadFavs();
    }
    setState(() {});
  }

  Future<void> _loadFavs() async {
    if (widget.channelList == null) return;
    for (var c in widget.channelList!) {
      _favs[c['url']] = await Fav.isFav('live', c['url']);
    }
    setState(() {});
  }

  Future<void> _play(int i) async {
    final ch = widget.channelList![i];
    await _vc.pause();
    await _vc.dispose();
    _chewie?.dispose();

    _idx = i;
    setState(() => _showList = false);

    _vc = VideoPlayerController.networkUrl(Uri.parse(ch['url']));
    await _vc.initialize();
    await _vc.setLooping(true);
    await _vc.play();
    setState(() {});
  }

  Future<void> _toggleFav() async {
    final ch = widget.channelList![_idx];
    bool added = await Fav.toggle('live', {
      'id': ch['url'],
      'name': ch['name'],
      'logo': ch['logo'],
    });
    setState(() => _favs[ch['url']] = added);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _vc.dispose();
    _chewie?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // VOD - أفلام ومسلسلات
    if (!isLive) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.goBack ||
                 event.logicalKey == LogicalKeyboardKey.escape)) {
              Navigator.pop(context);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: _vc.value.isInitialized
             ? Chewie(controller: _chewie!)
              : const Center(child: CircularProgressIndicator(color: Colors.red)),
        ),
      );
    }

    // LIVE TV
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;

          if (!_showList) {
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              setState(() => _showList = true);
              return KeyEventResult.handled;
            }
          } else {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp && _idx > 0) {
              setState(() => _idx--);
              _scroll.animateTo(_idx * 56.0, duration: const Duration(milliseconds: 150), curve: Curves.ease);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown && _idx < widget.channelList!.length - 1) {
              setState(() => _idx++);
              _scroll.animateTo(_idx * 56.0, duration: const Duration(milliseconds: 150), curve: Curves.ease);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.select) {
              _play(_idx);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _toggleFav();
              return KeyEventResult.handled;
            }
          }

          if (event.logicalKey == LogicalKeyboardKey.goBack) {
            if (_showList) {
              setState(() => _showList = false);
            } else {
              Navigator.pop(context);
            }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _vc.value.isInitialized
               ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _vc.value.size.width,
                        height: _vc.value.size.height,
                        child: VideoPlayer(_vc),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator(color: Colors.red)),

            if (_showList)
              Positioned(
                right: 30, top: 70, bottom: 70, width: 400,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: ListView.builder(
                    controller: _scroll,
                    itemCount: widget.channelList!.length,
                    itemBuilder: (_, i) {
                      final ch = widget.channelList![i];
                      final active = i == _idx;
                      return Container(
                        height: 56,
                        color: active? Colors.red : Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ch['name']?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: active? 17 : 14,
                                  fontWeight: active? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (_favs[ch['url']] == true)
                              const Icon(Icons.favorite, color: Colors.white, size: 16),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
