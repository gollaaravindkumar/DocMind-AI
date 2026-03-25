import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glowing_button.dart';
import 'main_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Particle background simulation
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.network(
                'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=1000&auto=format&fit=crop',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brain Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.5),
                        blurRadius: 60,
                        spreadRadius: 20,
                      )
                    ],
                  ),
                  child: const Icon(Icons.psychology, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 40),
                Text(
                  'DocMind AI',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.8),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ask anything. Find everything.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF06B6D4),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 60),
                GlowingButton(
                  text: 'Get Started',
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => MainScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
