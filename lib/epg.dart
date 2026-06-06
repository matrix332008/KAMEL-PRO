import 'package:flutter/material.dart';

class EPGScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Text('EPG - Coming Soon', style: TextStyle(color: Colors.white, fontSize: 24)),
        ),
      ),
    );
  }
}
