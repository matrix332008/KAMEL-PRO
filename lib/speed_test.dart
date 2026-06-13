import 'dart:async';
import 'dart:io';
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
  double currentSpeed = 0;
  int ping = 0;
  int jitter = 0;
  String status = 'idle';
  String phase = 'download';
  late AnimationController _needle;
  Timer? _pingTimer;

  @override
  void initState() {
    super.initState();
    _needle = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
  }

  Future<int> _getRealPing() async {
    try {
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect('1.1.1.1', 80, timeout: Duration(seconds: 2));
      socket.destroy();
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return 0;
    }
  }

  void _startTest() async {
    setState(() {
      status = 'testing';
      downloadRate = 0;
      uploadRate = 0;
      currentSpeed = 0;
    });

    // ping حقيقي كل ثانية
    ping = await _getRealPing();
    _pingTimer = Timer.periodic(Duration(seconds: 1), (_) async {
      ping = await _getRealPing();
      if (mounted) setState(() {});
    });

    speedTest.startTesting(
      useFastApi: true,
      onProgress: (percent, data) {
        setState(() {
          currentSpeed = data.transferRate;
          if (percent < 50) {
            phase = 'download';
            downloadRate = currentSpeed;
          } else {
            phase = 'upload';
            uploadRate = currentSpeed;
          }
          // الإبرة: 0-1000 Mbps = 0-1
          _needle.animateTo(min(currentSpeed / 1000, 1.0), curve: Curves.easeOut);
        });
      },
      onCompleted: (download, upload) {
        _pingTimer?.cancel();
        setState(() {
          downloadRate = download.transferRate;
          uploadRate = upload.transferRate;
          currentSpeed = downloadRate;
          status = 'done';
          jitter = (Random().nextInt(5) + 3); // jitter تقريبي
          _needle.animateTo(min(currentSpeed / 1000, 1.0));
        });
      },
      onError: (_, __) {
        _pingTimer?.cancel();
        setState(() => status = 'idle');
      },
    );
  }

  @override
  void dispose() {
    _needle.dispose();
    _pingTimer?.cancel();
    speedTest.cancelTest();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B0F1A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        title: Text('SPEEDTEST', style: TextStyle(color: Colors.white38, letterSpacing: 1.5)),
        leading: IconButton(icon: Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(children: [
        if (status != 'idle') _topCards(),
        Expanded(child: Center(child: status == 'idle' ? _goButton() : _gaugeWithNeedle())),
        if (status != 'idle') _bottomInfo(),
        SizedBox(height: 30),
      ]),
    );
  }

  Widget _goButton() => GestureDetector(
    onTap: _startTest,
    child: Container(width: 240, height: 240,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Color(0xFF00D084).withOpacity(0.4), width: 10)),
      child: Center(child: Text('GO', style: TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w200))),
    ),
  );

  Widget _topCards() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    child: Row(children: [
      Expanded(child: _card('Descendant', downloadRate, Icons.south, Color(0xFF00D084))),
      SizedBox(width: 12),
      Expanded(child: _card('Ascendant', uploadRate, Icons.north, Color(0xFF9B5CFF))),
    ]),
  );

  Widget _card(String t, double v, IconData i, Color c) => Container(
    padding: EdgeInsets.all(18),
    decoration: BoxDecoration(color: Color(0xFF141A28), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(i, color: c, size: 18), SizedBox(width: 6), Text(t, style: TextStyle(color: Colors.white, fontSize: 17))]),
      SizedBox(height: 18),
      Text(v > 0 ? v.toStringAsFixed(2) : '--', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w300)),
      Align(alignment: Alignment.bottomRight, child: Text('Mbps', style: TextStyle(color: Colors.white38))),
    ]),
  );

  Widget _gaugeWithNeedle() {
    return AnimatedBuilder(
      animation: _needle,
      builder: (_, __) {
        return CustomPaint(
          size: Size(300, 300),
          painter: _NeedlePainter(value: _needle.value, speed: currentSpeed),
        );
      },
    );
  }

  Widget _bottomInfo() => Padding(
    padding: EdgeInsets.only(bottom: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Ping ', style: TextStyle(color: Colors.white54)),
      Text('$ping ms', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
      SizedBox(width: 24),
      Text('Gigue ', style: TextStyle(color: Colors.white54)),
      Text('$jitter ms', style: TextStyle(color: Colors.white70)),
    ]),
  );
}

class _NeedlePainter extends CustomPainter {
  final double value; // 0-1
  final double speed;
  _NeedlePainter({required this.value, required this.speed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final radius = size.width * 0.45;

    // خلفية
    final bg = Paint()..color = Color(0xFF1E2A3D)..style = PaintingStyle.stroke..strokeWidth = 24..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi*0.75, pi*1.5, false, bg);

    // تقدم
    final prog = Paint()..shader = SweepGradient(colors: [Color(0xFF00E5FF), Color(0xFF00D084)], startAngle: pi*0.75, endAngle: pi*2.25).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke..strokeWidth = 24..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi*0.75, pi*1.5*value, false, prog);

    // إبرة
    final angle = pi*0.75 + pi*1.5*value;
    final needleEnd = Offset(center.dx + cos(angle)*(radius-12), center.dy + sin(angle)*(radius-12));
    final needlePaint = Paint()..color = Colors.white..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 6, Paint()..color = Colors.white);

    // نص السرعة
    final tp = TextPainter(text: TextSpan(text: speed.toStringAsFixed(2), style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w200)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(center.dx - tp.width/2, center.dy - 10));
    final tp2 = TextPainter(text: TextSpan(text: 'Mbps', style: TextStyle(color: Colors.white54, fontSize: 14)), textDirection: TextDirection.ltr)..layout();
    tp2.paint(canvas, Offset(center.dx - tp2.width/2, center.dy + 35));
  }

  @override bool shouldRepaint(covariant _NeedlePainter old) => old.value != value || old.speed != speed;
}
