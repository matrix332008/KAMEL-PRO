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

  @override State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool isLive = false;
  bool _showChannelList = false;
  int _listIndex = 0;
  final ScrollController _channelScroll = ScrollController();
  Map<String,bool> _favs = {};

  @override void initState() {
    super.initState();
    isLive = widget.url.contains('/live/');
    _listIndex = widget.currentIndex?? 0;
    _initializePlayer(widget.url);
    _loadFavs();
  }

  Future<void> _loadFavs() async {
    if (widget.channelList == null) return;
    for (var ch in widget.channelList!) {
      String id = _getId(ch);
      _favs[id] = await Fav.isFav('live', id);
    }
    if (mounted) setState(() {});
  }

  String _getId(Map ch) => (ch['url']?? ch['name']?? '').toString();

  Future<void> _initializePlayer(String url) async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      isLive: isLive,
      allowFullScreen: true,
      showControls: true,
    );
    setState(() {});
  }

  void _playChannel(int index) {
    if (widget.channelList == null) return;
    final ch = widget.channelList![index];
    _chewieController?.dispose();
    _videoController.dispose();
    _listIndex = index;
    _initializePlayer(ch['url']);
    setState(() => _showChannelList = false);
  }

  void _toggleFav(Map ch) async {
    String id = _getId(ch);
    bool added = await Fav.toggle('live', {'id': id, 'name': ch['name'], 'logo': ch['logo']});
    setState(() => _favs[id] = added);
  }

  @override void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && isLive && widget.channelList!= null) {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (_listIndex > 0) _playChannel(_listIndex - 1);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (_listIndex < widget.channelList!.length - 1) _playChannel(_listIndex + 1);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.select) {
              setState(() => _showChannelList =!_showChannelList);
              return KeyEventResult.handled;
            }
          }
          if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.goBack || event.logicalKey == LogicalKeyboardKey.escape)) {
            Navigator.pop(context);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            Center(
              child: _chewieController!= null && _chewieController!.videoPlayerController.value.isInitialized
                 ? Chewie(controller: _chewieController!)
                  : CircularProgressIndicator(color: Colors.cyan),
            ),
            // عنوان القناة
            if (widget.title!= null)
              Positioned(
                top: 40,
                left: 20,
                child: Text(widget.title!, style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
            // قائمة القنوات - تم التعديل هنا
            if (isLive && _showChannelList && widget.channelList!= null)
              Positioned(
                right: 30,
                top: 80,
                bottom: 80,
                width: 380,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan, width: 2),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('القنوات', style: TextStyle(color: Colors.cyan, fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _channelScroll,
                          itemCount: widget.channelList!.length,
                          itemBuilder: (_, i) {
                            final ch = widget.channelList![i];
                            final active = i == _listIndex;
                            final id = _getId(ch);
                            final isFav = _favs[id] == true;
                            return GestureDetector(
                              onTap: () => _playChannel(i),
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: active? Colors.cyan : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    if (ch['logo']!= null && ch['logo'].toString().isNotEmpty)
                                      Image.network(ch['logo'], width: 32, height: 32, errorBuilder: (_, __, ___) => Icon(Icons.tv, color: Colors.white30, size: 24))
                                    else
                                      Icon(Icons.tv, color: Colors.white30, size: 24),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        ch['name']?? '',
                                        style: TextStyle(color: active? Colors.black : Colors.white, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _toggleFav(ch),
                                      child: Icon(isFav? Icons.favorite : Icons.favorite_border, size: 18, color: isFav? Colors.red : Colors.white54),
                                    ),
                                  ],
                                ),
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
}
