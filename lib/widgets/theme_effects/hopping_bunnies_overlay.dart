import 'dart:math';
import 'package:flutter/material.dart';

class HoppingBunniesOverlay extends StatefulWidget {
  const HoppingBunniesOverlay({super.key});

  @override
  State<HoppingBunniesOverlay> createState() => _HoppingBunniesOverlayState();
}

class _HoppingBunniesOverlayState extends State<HoppingBunniesOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Bunny> _bunnies;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )
      ..addListener(() => setState(() {}))
      ..repeat();
    _bunnies = [];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ensureBunnies(Size size) {
    if (_bunnies.isNotEmpty) return;
    final rand = Random();
    // 5-8 bunnies across the bottom
    final count = 6;
    _bunnies.addAll(List.generate(count, (i) {
      final speed = 0.8 + rand.nextDouble() * 0.8; // 0.8..1.6
      final phase = rand.nextDouble() * pi * 2;
      final yBase = size.height - (40 + rand.nextDouble() * 20);
      final emoji = i.isEven ? '🐰' : '🐇';
      final color = i % 3 == 0
          ? Colors.pinkAccent
          : i % 3 == 1
              ? Colors.purpleAccent
              : Colors.lightBlueAccent;
      return _Bunny(
        x: rand.nextDouble() * size.width,
        yBase: yBase,
        speed: speed,
        hopAmp: 12 + rand.nextDouble() * 10,
        phase: phase,
        emoji: emoji,
        color: color,
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _ensureBunnies(size);
        return IgnorePointer(
          child: CustomPaint(
            painter: _BunnyPainter(_bunnies, size),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _Bunny {
  double x;
  final double yBase;
  final double speed; // px per tick
  final double hopAmp;
  double phase; // radians
  final String emoji;
  final Color color;

  _Bunny({
    required this.x,
    required this.yBase,
    required this.speed,
    required this.hopAmp,
    required this.phase,
    required this.emoji,
    required this.color,
  });

  void update(Size size) {
    phase += 0.1;
    x += speed;
    if (x > size.width + 30) x = -30;
  }

  Offset position(Size size) {
    final y = yBase - sin(phase) * hopAmp;
    return Offset(x, y);
  }
}

class _BunnyPainter extends CustomPainter {
  final List<_Bunny> bunnies;
  final Size size;
  _BunnyPainter(this.bunnies, this.size);

  @override
  void paint(Canvas canvas, Size s) {
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (final b in bunnies) {
      b.update(size);
      final pos = b.position(size);
      // Draw a soft shadow ellipse under the bunny
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(pos.dx, b.yBase + 6), width: 26, height: 8),
        shadowPaint,
      );

      // Color halo behind emoji for pastel feel
      final halo = Paint()
        ..color = b.color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos.translate(0, -8), 14, halo);

      // Draw the bunny emoji
      tp.text = TextSpan(text: b.emoji, style: const TextStyle(fontSize: 22));
      tp.layout();
      tp.paint(canvas, pos.translate(-tp.width / 2, -tp.height));
    }
  }

  @override
  bool shouldRepaint(covariant _BunnyPainter oldDelegate) => true;
}
