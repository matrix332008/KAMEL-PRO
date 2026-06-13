import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';

class SpeedTestScreen extends StatefulWidget {
  @override
  _SpeedTestScreenState createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> with SingleTickerProviderStateMixin {
  final speedTest = FlutterInternetSpeedTest();
  double downloadRate = 0;
  double uploadRate = 0;
  double displayRate = 0;
  int ping = 0;
  int jitter = 0;
  String status = 'idle'; // idle, testing, done
  String phase = '';
  late AnimationController _needleCtrl;

  @override
  void initState() {
    super.initState();
    _needleCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
  }

  void _startTest() {
    setState(() {
      status = 'testing';
      downloadRate = 0;
      uploadRate = 0;
      displayRate = 0;
      phase = 'download';
    });

    speedTest.startTesting(
      useFastApi: true,
      onStarted: () {},
      onProgress: (percent, data) {
        setState(() {
          if (percent < 50) {
            phase = 'download';
            downloadRate = data.transferRate;
            displayRate = downloadRate;
          } else {
            phase = 'upload';
            uploadRate = data.transferRate;
            displayRate = uploadRate;
          }
          _needleCtrl.animateTo(min(displayRate / 1000, 1.0));
        });
      },
      onCompleted: (download, upload) {
        setState(() {
          downloadRate = download.transferRate;
          uploadRate = upload.transferRate;
          displayRate = downloadRate;
          status = 'done';
          ping = 15; // الـ package ما يعطيش ping، نحطو قيمة demo
          jitter = 8;
          _needleCtrl.animateTo(min(displayRate / 1000, 1.0));
        });
      },
      onError: (msg, err) {
        setState(() => status = 'idle');
      },
    );
  }

  @override
  void dispose() {
    _needleCtrl.dispose();
    speedTest.cancelTest();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.speed, color: Colors.white38, size: 20),
          SizedBox(width: 6),
          Text('SPEEDTEST', style: TextStyle(color: Colors.white38, letterSpacing: 1.2)),
        ]),
        leading: IconButton(icon: Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          if (status != 'idle') _topCards(),
          Expanded(
            child: Center(
              child: status == 'idle' ? _goButton() : _gauge(),
            ),
          ),
          if (status != 'idle') _bottomInfo(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _goButton() {
    return GestureDetector(
      onTap: _startTest,
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Color(0xFF00D084).withOpacity(0.3), width: 8),
          boxShadow: [BoxShadow(color: Color(0xFF00D084).withOpacity(0.2), blurRadius: 30)],
        ),
        child: Container(
          margin: EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFF00D084), width: 2),
          ),
          child: Center(child: Text('GO', style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w300, letterSpacing: 2))),
        ),
      ),
    );
  }

  Widget _topCards() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(child: _metricCard('Descendant', downloadRate, Icons.arrow_downward, Color(0xFF00D084))),
          SizedBox(width: 12),
          Expanded(child: _metricCard('Ascendant', uploadRate, Icons.arrow_upward, Color(0xFF9B5CFF))),
        ],
      ),
    );
  }

  Widget _metricCard(String label, double value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF141A28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color, size: 16), SizedBox(width: 6), Text(label, style: TextStyle(color: Colors.white, fontSize: 16))]),
        SizedBox(height: 20),
        Text(value > 0 ? value.toStringAsFixed(2) : '--', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300)),
        Align(alignment: Alignment.bottomRight, child: Text('Mbps', style: TextStyle(color: Colors.white38, fontSize: 12))),
      ]),
    );
  }

  Widget _gauge() {
    return Container(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(320, 320), painter: _GaugePainter(progress: _needleCtrl.value)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(displayRate.toStringAsFixed(2), style: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w200)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(phase == 'download' ? Icons.arrow_downward : Icons.arrow_upward, color: Color(0xFF00D084), size: 16),
              SizedBox(width: 4),
              Text('Mbps', style: TextStyle(color: Colors.white54)),
            ]),
          ]),
        ],
      ),
    );
  }

  Widget _bottomInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _infoChip('Ping', '${ping} ms', Colors.amber),
          SizedBox(width: 20),
          _infoChip('Gigue', '${jitter} ms', Colors.white54),
        ]),
        SizedBox(height: 16),
        Text('Vodafone • Prague', style: TextStyle(color: Colors.white38, fontSize: 13)),
      ]),
    );
  }

  Widget _infoChip(String label, String value, Color c) => Row(children: [
    Text('$label ', style: TextStyle(color: Colors.white54)),
    Text(value, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
  ]);
}

class _GaugePainter extends CustomPainter {
  final double progress;
  _GaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    final bgPaint = Paint()
      ..color = Color(0xFF1E2A3D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -3.14 * 0.8, 3.14 * 1.6, false, bgPaint);

    final activePaint = Paint()
      ..shader = SweepGradient(colors: [Color(0xFF00D084), Color(0xFF00BFFF)], startAngle: -2.5, endAngle: 2.5).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -3.14 * 0.8, 3.14 * 1.6 * progress, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.progress != progress;
}
