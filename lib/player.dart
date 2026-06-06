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
  const PlayerScreen({required this.url, this.title, this.logo, this.channelList, this.currentIndex, super.key});

  @override State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _vc;
  ChewieController? _chewie;
  bool isLive = false;
  bool _showList = false;
  int _idx = 0;
  Map<String,bool> _favs = {};

  @override void initState() {
    super.initState();
    isLive = widget.url.contains('/live/');
    _idx = widget.currentIndex?? 0;
    _init(widget.url);
    _loadFavs();
  }

  Future<void> _loadFavs() async {
    if (widget.channelList == null) return;
    for (var c in widget.channelList!) {
      String id = (c['url']??'').toString();
      _favs[id] = await Fav.isFav('live', id);
    }
    setState((){});
  }

  Future<void> _init(String url) async {
    _vc = VideoPlayerController.networkUrl(Uri.parse(url));
    await _vc.initialize();
    if (!isLive) {
      _chewie = ChewieController(
        videoPlayerController: _vc,
        autoPlay: true,
        isLive: false,
        showControls: true,
        allowFullScreen: true,
      );
    } else {
      _vc.setLooping(true);
      _vc.play();
    }
    setState(() {});
  }

  void _play(int i) {
    final ch = widget.channelList![i];
    _vc.dispose();
    _chewie?.dispose();
    _idx = i;
    _init(ch['url']);
    setState(() => _showList = false);
  }

  void _toggleFav() async {
    final ch = widget.channelList![_idx];
    String id = ch['url'];
    bool added = await Fav.toggle('live', {'id':id,'name':ch['name'],'logo':ch['logo']});
    setState(()=> _favs[id]=added);
  }

  @override void dispose() {
    _vc.dispose();
    _chewie?.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;

          // للأفلام والمسلسلات خلي Chewie يخدم وحدو
          if (!isLive) {
            if (event.logicalKey == LogicalKeyboardKey.goBack) {
              Navigator.pop(context);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          }

          // LIVE TV
          if (!_showList) {
            if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
              setState(()=> _showList = true);
              return KeyEventResult.handled;
            }
          } else {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp && _idx > 0) {
              setState(()=> _idx--);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown && _idx < widget.channelList!.length-1) {
              setState(()=> _idx++);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
              _play(_idx);
              return KeyEventResult.handled;
            }
            // ضغطة مطولة = نستعمل زر MENU للريموت
            if (event.logicalKey == LogicalKeyboardKey.contextMenu) {
              _toggleFav();
              return KeyEventResult.handled;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.goBack) {
            if (_showList) { setState(()=> _showList=false); }
            else { Navigator.pop(context); }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // فيديو يملأ الشاشة كاملة (من غير كحل)
            Center(
              child: _vc.value.isInitialized
               ? isLive
                 ? SizedBox.expand(child: FittedBox(fit: BoxFit.cover, child: SizedBox(width: _vc.value.size.width, height: _vc.value.size.height, child: VideoPlayer(_vc))))
                  : Chewie(controller: _chewie!)
                : CircularProgressIndicator(color: Colors.red),
            ),
            // قائمة القنوات
            if (isLive && _showList && widget.channelList!= null)
              Positioned(
                right: 40, top: 80, bottom: 80, width: 400,
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red, width: 2)),
                  child: ListView.builder(
                    itemCount: widget.channelList!.length,
                    itemBuilder: (_, i) {
                      final ch = widget.channelList![i];
                      final active = i == _idx;
                      final fav = _favs[ch['url']] == true;
                      return Container(
                        color: active? Colors.red : Colors.transparent,
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(child: Text(ch['name']??'', style: TextStyle(color: Colors.white, fontSize: active?18:16))),
                            if (fav) Icon(Icons.favorite, color: Colors.white, size: 18),
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
