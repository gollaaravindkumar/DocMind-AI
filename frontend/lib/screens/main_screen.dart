import 'package:flutter/material.dart';
import 'upload_screen.dart';
import 'chat_screen.dart';
import 'podcast_screen.dart';
import 'analytics_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      UploadScreen(onStartQuerying: () {
        setState(() {
          _currentIndex = 1;
        });
      }),
      const ChatScreen(),
      const PodcastScreen(),
      const AnalyticsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.black,
          selectedItemColor: const Color(0xFF06B6D4),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: 'Upload'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Ask AI'),
            BottomNavigationBarItem(icon: Icon(Icons.podcasts), label: 'Podcast'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Insights'),
          ],
        ),
      ),
    );
  }
}
