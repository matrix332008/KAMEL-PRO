import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class PlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  PlayerScreen({required this.url, required this.title});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _isPlaying = true;
        _hideControlsAfterDelay();
      });

    _controller.addListener(() {
      if (_controller.value.isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = _controller.value.isPlaying;
        });
      }
    });
  }

  _hideControlsAfterDelay() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
        _hideControlsAfterDelay();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
          if (_showControls) _hideControlsAfterDelay();
        },
        child: Stack(
          children: [
            Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : CircularProgressIndicator(color: Colors.cyan),
            ),
            if (_showControls)
              Container(
                color: Colors.black54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: TextStyle(color: Colors.white, fontSize: 20),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.replay_10, color: Colors.white, size: 40),
                          onPressed: () {
                            final pos = _controller.value.position - Duration(seconds: 10);
                            _controller.seekTo(pos);
                          },
                        ),
                        SizedBox(width: 40),
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 70,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                        SizedBox(width: 40),
                        IconButton(
                          icon: Icon(Icons.forward_10, color: Colors.white, size: 40),
                          onPressed: () {
                            final pos = _controller.value.position + Duration(seconds: 10);
                            _controller.seekTo(pos);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
