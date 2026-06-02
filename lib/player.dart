import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class PlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final List<dynamic>? channelList;
  final int? currentIndex;

  PlayerScreen({required this.url, required this.title, this.channelList, this.currentIndex});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VlcPlayerController _vlcController;
  bool _showControls = true;
  bool _showChannelList = false;
  String _channelNumber = '';
  int _currentIndex = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex?? 0;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _initializePlayer(widget.url);
    _focusNode.requestFocus();
  }

  _initializePlayer(String url) {
    _vlcController = VlcPlayerController.network(
      url,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
    _hideControls();
  }

  _hideControls() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted &&!_showChannelList) {
        setState(() => _showControls = false);
      }
    });
  }

  _playChannel(int index) {
    if (widget.channelList == null || index < 0 || index >= widget.channelList!.length) return;
    setState(() {
      _currentIndex = index;
      _showChannelList = false;
    });
    _vlcController.setMediaFromNetwork(widget.channelList![index]['stream_url']?? '');
    _vlcController.play();
  }

  _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
        if (_showChannelList) {
          _playChannel(_currentIndex);
        } else {
          setState(() => _showChannelList =!_showChannelList);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_showChannelList) {
          setState(() => _currentIndex = (_currentIndex - 1).clamp(0, (widget.channelList?.length?? 1) - 1));
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_showChannelList) {
          setState(() => _currentIndex = (_currentIndex + 1).clamp(0, (widget.channelList?.length?? 1) - 1));
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_showChannelList) {
          setState(() => _showChannelList = false);
        } else {
          Navigator.pop(context);
        }
      } else if (event.logicalKey.keyLabel.length == 1 && int.tryParse(event.logicalKey.keyLabel)!= null) {
        setState(() {
          _channelNumber += event.logicalKey.keyLabel;
          if (_channelNumber.length >= 3) {
            int? num = int.tryParse(_channelNumber);
            if (num!= null && num > 0 && widget.channelList!= null && num <= widget.channelList!.length) {
              _playChannel(num - 1);
            }
            _channelNumber = '';
          }
        });
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) setState(() => _channelNumber = '');
        });
      }
    }
  }

  @override
  void dispose() {
    _vlcController.dispose();
    _focusNode.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentTitle = widget.channelList!= null && _currentIndex < widget.channelList!.length
       ? widget.channelList![_currentIndex]['name']
        : widget.title;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => setState(() => _showControls =!_showControls),
          child: Stack(
            children: [
              Center(child: VlcPlayer(controller: _vlcController, aspectRatio: 16 / 9, placeholder: Center(child: CircularProgressIndicator(color: Colors.cyan)))),
              if (_showControls || _showChannelList)
                Positioned(
                  top: 30,
                  left: 30,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(10)),
                    child: Text(currentTitle, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (_channelNumber.isNotEmpty)
                Center(
                  child: Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
                    child: Text(_channelNumber, style: TextStyle(color: Colors.cyan, fontSize: 80, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (_showChannelList && widget.channelList!= null)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 350,
                    color: Colors.black.withOpacity(0.9),
                    child: ListView.builder(
                      itemCount: widget.channelList!.length,
                      itemBuilder: (context, index) {
                        bool selected = index == _currentIndex;
                        return Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: selected? Colors.cyan.withOpacity(0.3) : Colors.transparent,
                            border: Border.all(color: selected? Colors.cyan : Colors.transparent, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text('${index + 1}.', style: TextStyle(color: Colors.cyan, fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(width: 10),
                              Expanded(child: Text(widget.channelList![index]['name']?? '', style: TextStyle(color: Colors.white, fontSize: 16), overflow: TextOverflow.ellipsis)),
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
      ),
    );
  }
}
