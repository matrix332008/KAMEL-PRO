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
    super.key
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _vc;
  ChewieController? _chewie;
  bool isLive = false;
  bool _showList = false;
  bool _showInfo = false;
  int _idx = 0;
  Map<String, bool> _favs = {};
  final ScrollController _listScroll = ScrollController();
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    isLive = widget.url.contains('/live/');
    _idx = widget.currentIndex?? 0;
    _initPlayer(widget.url);
    _loadFavs();
  }

  Future<void> _loadFavs() async {
    if (widget.channelList == null) return;
    for (var c in widget.channelList!) {
      String id = (c['url']?? '').toString();
      _favs[id] = await Fav.isFav('live', id);
    }
    if (mounted) setState(() {});
  }

  Future<void> _initPlayer(String url) async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      _vc = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
      await _vc.initialize();

      if (!isLive) {
        _chewie = ChewieController(
          videoPlayerController: _vc,
          autoPlay: true,
          looping: false,
          isLive: false,
          showControls: true,
          allowFullScreen: true,
          allowMuting: true,
          showControlsOnInitialize: false,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.red,
            handleColor: Colors.red,
            backgroundColor: Colors.white24,
            bufferedColor: Colors.white38,
          ),
        );
      } else {
        await _vc.setLooping(true);
        await _vc.play();
        _showChannelInfo();
      }
    } catch (e) {
      debugPrint('Player init error: $e');
    }

    _isInitializing = false;
    if (mounted) setState(() {});
  }

  void _showChannelInfo() {
    if (!isLive || widget.title == null) return;
    setState(() => _showInfo = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showInfo = false);
    });
  }

  Future<void> _playChannel(int index) async {
    if (widget.channelList == null || index < 0 || index >= widget.channelList!.length) return;

    final ch = widget.channelList![index];
    final newUrl = ch['url']?.toString()?? '';
    if (newUrl.isEmpty) return;

    // سكر القديم
    try {
      await _vc.pause();
      await _vc.dispose();
    } catch (_) {}
    _chewie?.dispose();
    _chewie = null;

    setState(() {
      _idx = index;
      _showList = false;
      _showInfo = false;
    });

    await _initPlayer(newUrl);
    _showChannelInfo();
  }

  Future<void> _toggleFav() async {
    if (widget.channelList == null) return;
    final ch = widget.channelList![_idx];
    String id = ch['url']?.toString()?? '';
    if (id.isEmpty) return;

    bool added = await Fav.toggle('live', {
      'id': id,
      'name': ch['name'],
      'logo': ch['logo'],
    });

    setState(() => _favs[id] = added);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(added? 'تمت الإضافة للمفضلة' : 'تم الحذف من المفضلة'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scrollToCurrent() {
    if (!_listScroll.hasClients) return;
    final offset = _idx * 56.0;
    _listScroll.animateTo(
      offset.clamp(0, _listScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _listScroll.dispose();
    _vc.dispose();
    _chewie?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;

          // للأفلام والمسلسلات - خلي Chewie يتحكم
          if (!isLive) {
            if (event.logicalKey == LogicalKeyboardKey.goBack ||
                event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          }

          // LIVE TV Controls
          if (!_showList) {
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              setState(() => _showList = true);
              Future.delayed(const Duration(milliseconds: 100), _scrollToCurrent);
              return KeyEventResult.handled;
            }
          } else {
            // القائمة مفتوحة
            if (event.logicalKey == LogicalKeyboardKey.arrowUp && _idx > 0) {
              setState(() => _idx--);
              _scrollToCurrent();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
                _idx < widget.channelList!.length - 1) {
              setState(() => _idx++);
              _scrollToCurrent();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              _playChannel(_idx);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.contextMenu ||
                event.logicalKey == LogicalKeyboardKey.f1 ||
                event.logicalKey == LogicalKeyboardKey.f2) {
              _toggleFav();
              return KeyEventResult.handled;
            }
          }

          // زر الرجوع
          if (event.logicalKey == LogicalKeyboardKey.goBack ||
              event.logicalKey == LogicalKeyboardKey.escape) {
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
            // الفيديو - يملأ الشاشة كاملة
            Center(
              child: _vc.value.isInitialized
                 ? isLive
                     ? SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _vc.value.size.width,
                              height: _vc.value.size.height,
                              child: VideoPlayer(_vc),
                            ),
                          ),
                        )
                      : Chewie(controller: _chewie!)
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Colors.red,
                        strokeWidth: 3,
                      ),
                    ),
            ),

            // معلومات القناة فوق
            if (_showInfo && widget.title!= null)
              Positioned(
                top: 40,
                left: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.logo!= null && widget.logo!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Image.network(
                            widget.logo!,
                            width: 32,
                            height: 32,
                            errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: Colors.white, size: 24),
                          ),
                        ),
                      Text(
                        widget.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // قائمة القنوات
            if (isLive && _showList && widget.channelList!= null)
              Positioned(
                right: 40,
                top: 80,
                bottom: 80,
                width: 420,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.red, width: 1)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.live_tv, color: Colors.red, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'القنوات المباشرة',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _listScroll,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: widget.channelList!.length,
                          itemBuilder: (_, i) {
                            final ch = widget.channelList![i];
                            final active = i == _idx;
                            final fav = _favs[ch['url']] == true;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: active? Colors.red : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: ch['logo']!= null && ch['logo'].toString().isNotEmpty
                                   ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          ch['logo'],
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.tv,
                                            color: active? Colors.white : Colors.white54,
                                            size: 24,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.tv,
                                        color: active? Colors.white : Colors.white54,
                                        size: 24,
                                      ),
                                title: Text(
                                  ch['name']?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: active? Colors.white : Colors.white70,
                                    fontSize: active? 16 : 14,
                                    fontWeight: active? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: fav
                                   ? const Icon(Icons.favorite, color: Colors.white, size: 18)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.white12)),
                        ),
                        child: const Text(
                          'OK للاختيار • MENU للمفضلة',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 12),
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
}
