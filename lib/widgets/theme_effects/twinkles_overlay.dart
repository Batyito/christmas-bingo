import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/performance.dart';

class TwinklesOverlay extends StatefulWidget {
  const TwinklesOverlay({super.key});

  @override
  State<TwinklesOverlay> createState() => _TwinklesOverlayState();
}

class _TwinklesOverlayState extends State<TwinklesOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _rand = Random();
  final List<_Twinkle> _twinkles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )
      ..addListener(_tick)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tick() {
    final dt = 1 / 60.0;
    setState(() {
      for (final t in _twinkles) {
        t.update(dt);
      }
      _twinkles.removeWhere((t) => t.progress >= 1.0);
    });
  }

  void _spawnIfNeeded(Size size, double scale) {
    // Target count scales with area and performance scale, modest limits to avoid overdraw
    final base = (size.width * size.height) / 24000.0; // ~40 on 1080p logical
    final target = (base * scale).clamp(12.0, 42.0).round();
    if (_twinkles.length < target) {
      final deficit = target - _twinkles.length;
      for (int i = 0; i < deficit; i++) {
        _twinkles.add(_Twinkle.spawn(size, _rand));
      }
    } else if (_rand.nextDouble() < 0.05 && _twinkles.length < target + 2) {
      // occasional extra sparkle
      _twinkles.add(_Twinkle.spawn(size, _rand));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = performanceScaleFromContext(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _spawnIfNeeded(size, scale);
        return IgnorePointer(
          ignoring: true,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _TwinklePainter(_twinkles),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

class _Twinkle {
  double x, y;
  double angle;
  double progress; // 0..1
  double duration; // seconds
  double size; // base size
  _Twinkle(this.x, this.y, this.angle, this.progress, this.duration, this.size);

  factory _Twinkle.spawn(Size size, Random rand) {
    final x = rand.nextDouble() * size.width;
    final y = rand.nextDouble() * size.height;
    final angle = rand.nextDouble() * pi;
    final duration = 1.2 + rand.nextDouble() * 1.4; // 1.2..2.6s
    final bsize = 3.0 + rand.nextDouble() * 2.5; // 3..5.5 px arms
    return _Twinkle(x, y, angle, 0, duration, bsize);
  }

  void update(double dt) {
    progress += dt / duration;
    if (progress > 1.0) progress = 1.0;
  }
}

class _TwinklePainter extends CustomPainter {
  final List<_Twinkle> list;
  _TwinklePainter(this.list);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    for (final t in list) {
      final tEase = Curves.easeInOut
          .transform(1.0 - (t.progress - 0.5).abs() * 2)
          .clamp(0.0, 1.0);
      final glowAlpha = (180 * tEase).toInt().clamp(0, 255);
      final arm = t.size * (0.6 + 0.8 * tEase);

      // Draw glow halo
      final glow = Paint()
        ..color = Colors.white.withAlpha(glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(t.x, t.y), arm * 0.9, glow);

      canvas.save();
      canvas.translate(t.x, t.y);
      canvas.rotate(t.angle);

      // Two crossing lines (star)
      canvas.drawLine(Offset(-arm, 0), Offset(arm, 0), p);
      canvas.drawLine(Offset(0, -arm), Offset(0, arm), p);

      // Secondary 45-degree cross
      canvas.rotate(pi / 4);
      final faint = p..color = Colors.white.withValues(alpha: 0.65);
      canvas.drawLine(Offset(-arm * 0.7, 0), Offset(arm * 0.7, 0), faint);
      canvas.drawLine(Offset(0, -arm * 0.7), Offset(0, arm * 0.7), faint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _TwinklePainter oldDelegate) => true;
}
