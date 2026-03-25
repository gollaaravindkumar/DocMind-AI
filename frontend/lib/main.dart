import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const DocMindApp());
}

class DocMindApp extends StatelessWidget {
  const DocMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocMind AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black, // Pure black background
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C3AED),   // Neon Purple
          secondary: Color(0xFF06B6D4), // Electric Cyan
          surface: Colors.black,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
