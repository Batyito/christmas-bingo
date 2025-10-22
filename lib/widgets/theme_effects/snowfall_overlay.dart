import 'dart:math';
import 'package:flutter/material.dart';

class SnowfallOverlay extends StatefulWidget {
  const SnowfallOverlay({super.key});

  @override
  State<SnowfallOverlay> createState() => _SnowfallOverlayState();
}

class _SnowfallOverlayState extends State<SnowfallOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_Snowflake> _flakes;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )
      ..addListener(_tick)
      ..repeat();
    _flakes = [];
  }

  void _tick() {
    setState(() {
      for (final f in _flakes) {
        f.update();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ensureFlakes(Size size) {
    if (_flakes.isNotEmpty) return;
    // Density: ~1.2 flakes per 10x10 logical area for a nice effect, capped to ~120.
    final target = min(120, max(40, (size.width * size.height / 8000).round()));
    _flakes = List.generate(target, (_) => _Snowflake.spawn(size, _rand));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _ensureFlakes(size);
        return RepaintBoundary(
          child: CustomPaint(
            painter: _SnowPainter(_flakes),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _Snowflake {
  double x;
  double y;
  double r; // radius
  double vy; // fall speed
  double vx; // wind drift
  double swayPhase;
  final Size bounds;
  final Random rand;

  _Snowflake(this.x, this.y, this.r, this.vy, this.vx, this.swayPhase,
      this.bounds, this.rand);

  factory _Snowflake.spawn(Size size, Random rand) {
    final r = rand.nextDouble() * 2 + 1.2; // 1.2..3.2
    final vy = rand.nextDouble() * 1.2 + 0.6; // 0.6..1.8
    final vx = (rand.nextDouble() - 0.5) * 0.5; // slight wind drift
    final x = rand.nextDouble() * size.width;
    final y = rand.nextDouble() * size.height;
    final phase = rand.nextDouble() * pi * 2;
    return _Snowflake(x, y, r, vy, vx, phase, size, rand);
  }

  void update() {
    swayPhase += 0.02;
    x += vx + 0.6 * sin(swayPhase) * 0.3;
    y += vy;

    if (y - r > bounds.height) {
      // respawn at top
      y = -r - rand.nextDouble() * 20;
      x = rand.nextDouble() * bounds.width;
    }
    if (x < -5) x = bounds.width + 5;
    if (x > bounds.width + 5) x = -5;
  }
}

class _SnowPainter extends CustomPainter {
  final List<_Snowflake> flakes;
  _SnowPainter(this.flakes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2)
      ..isAntiAlias = true;

    for (final f in flakes) {
      canvas.drawCircle(Offset(f.x, f.y), f.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) {
    return true;
  }
}
