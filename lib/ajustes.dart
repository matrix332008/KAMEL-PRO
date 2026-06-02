import 'package:flutter/material.dart';

class AjustesScreen extends StatelessWidget {
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
          child: Text('AJUSTES - Coming Soon', style: TextStyle(color: Colors.white, fontSize: 24)),
        ),
      ),
    );
  }
}
