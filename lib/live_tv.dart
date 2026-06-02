import 'package:flutter/material.dart';
import 'player.dart';

class LiveTV extends StatelessWidget {
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
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
                    title: 'Test Channel',
                  ),
                ),
              );
            },
            child: Text('Test Player'),
          ),
        ),
      ),
    );
  }
}
