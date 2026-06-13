import 'package:flutter/material.dart';
import 'package:internet_speed_test/internet_speed_test.dart';

class SpeedTestScreen extends StatefulWidget {
  @override
  _SpeedTestScreenState createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> with SingleTickerProviderStateMixin {
  final speedTest = InternetSpeedTest();
  double downloadRate = 0;
  double uploadRate = 0;
  String status = 'جاهز';
  bool testing = false;
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat();
  }

  void _startTest() async {
    setState(() { testing = true; status = 'يختبر Download...'; downloadRate = 0; uploadRate = 0; });
    
    speedTest.startDownloadTesting(
      onDone: (_) {
        setState(() => status = 'يختبر Upload...');
        speedTest.startUploadTesting(
          onDone: (_) => setState(() { testing = false; status = 'اكتمل'; _ctrl.stop(); }),
          onProgress: (p, data) => setState(() => uploadRate = data.transferRate),
        );
      },
      onProgress: (p, data) => setState(() => downloadRate = data.transferRate),
      onError: (e, s) => setState(() { testing = false; status = 'خطأ'; }),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text('Speed Test'), backgroundColor: Colors.black),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          RotationTransition(
            turns: _ctrl,
            child: Icon(Icons.speed, size: 120, color: testing ? Colors.red : Colors.white30),
          ),
          SizedBox(height: 30),
          Text(status, style: TextStyle(color: Colors.white70, fontSize: 20)),
          SizedBox(height: 40),
          _card('DOWNLOAD', downloadRate, Colors.cyan),
          SizedBox(height: 20),
          _card('UPLOAD', uploadRate, Colors.orange),
          SizedBox(height: 50),
          ElevatedButton(
            onPressed: testing ? null : _startTest,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18)),
            child: Text(testing ? '...' : 'ابدأ', style: TextStyle(fontSize: 22)),
          ),
        ]),
      ),
    );
  }

  Widget _card(String label, double v, Color c) => Container(
    width: 280,
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16), border: Border.all(color: c)),
    child: Column(children: [
      Text(label, style: TextStyle(color: c)),
      Text('${v.toStringAsFixed(1)} Mbps', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
    ]),
  );
}
