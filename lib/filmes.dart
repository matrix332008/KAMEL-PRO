import 'package:flutter/material.dart';
import 'player.dart';

class FilmesScreen extends StatelessWidget {
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
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 20),
                  Text(
                    'FILMES',
                    style: TextStyle(color: Colors.red, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerScreen(
                          url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
                          title: 'Test Movie',
                        ),
                      ),
                    );
                  },
                  child: Text('Test Movie'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
