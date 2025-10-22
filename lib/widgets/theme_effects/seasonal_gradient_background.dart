import 'package:flutter/material.dart';

class SeasonalGradientBackground extends StatelessWidget {
  final String themeKey; // 'christmas' | 'easter' | 'dark'
  final double opacity; // allow slight transparency if desired
  const SeasonalGradientBackground(
      {super.key, required this.themeKey, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    final Gradient gradient;
    switch (themeKey) {
      case 'christmas':
        gradient = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4A0F0F), // deep wine
            Color(0xFF8A1D1D), // rich red
            Color(0xFF0F3D1E), // deep pine green
          ],
          stops: [0.0, 0.55, 1.0],
        );
        break;
      case 'easter':
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF431F5E), // deep purple base
            Color(0xFF7B4FA1), // soft violet
            Color(0xFFFF9EC4), // pastel pink
          ],
          stops: [0.0, 0.6, 1.0],
        );
        break;
      default:
        gradient = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0E0E10),
            Color(0xFF1C1E22),
          ],
        );
    }

    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
        ),
      ),
    );
  }
}
