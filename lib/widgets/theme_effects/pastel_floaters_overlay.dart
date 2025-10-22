import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/performance.dart';

class PastelFloatersOverlay extends StatefulWidget {
  const PastelFloatersOverlay({super.key});

  @override
  State<PastelFloatersOverlay> createState() => _PastelFloatersOverlayState();
}

class _PastelFloatersOverlayState extends State<PastelFloatersOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _rand = Random();
  final List<_Floater> _floaters = [];

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
    setState(() {
      for (final f in _floaters) {
        f.update();
      }
      _floaters.removeWhere((f) => f.isOffTop);
    });
  }

  void _ensureFloaters(Size size, double scale) {
    final base = (size.width * size.height) / 55000.0; // ~18 on 1080p logical
    final target = (base * scale).clamp(8.0, 24.0).round();
    while (_floaters.length < target) {
      _floaters.add(_Floater.spawn(size, _rand));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = performanceScaleFromContext(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _ensureFloaters(size, scale);
        return IgnorePointer(
          child: CustomPaint(
            painter: _FloaterPainter(_floaters, size),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _Floater {
  double x;
  double y;
  double vy; // upward speed
  double vxPhase; // for horizontal sway
  double swayAmp;
  String emoji; // 🦋 or 🥚
  Color halo;
  Size bounds;

  _Floater(this.x, this.y, this.vy, this.vxPhase, this.swayAmp, this.emoji,
      this.halo, this.bounds);

  factory _Floater.spawn(Size size, Random rand) {
    final x = rand.nextDouble() * size.width;
    final y = size.height + rand.nextDouble() * 80;
    final vy = -(0.35 + rand.nextDouble() * 0.4); // -0.35..-0.75 px per tick
    final phase = rand.nextDouble() * pi * 2;
    final amp = 14 + rand.nextDouble() * 10;
    final emoji = rand.nextBool() ? '🦋' : '🥚';
    final halos = [
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.lightBlueAccent,
      Colors.tealAccent,
      Colors.yellowAccent,
    ];
    final halo = halos[rand.nextInt(halos.length)].withValues(alpha: 0.25);
    return _Floater(x, y, vy, phase, amp, emoji, halo, size);
  }

  void update() {
    vxPhase += 0.04;
    x += sin(vxPhase) * 0.6; // gentle sway
    y += vy;
  }

  bool get isOffTop => y < -60;
}

class _FloaterPainter extends CustomPainter {
  final List<_Floater> list;
  final Size bounds;
  _FloaterPainter(this.list, this.bounds);

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (final f in list) {
      // Halo
      final haloPaint = Paint()
        ..color = f.halo
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(f.x, f.y - 8), 16, haloPaint);

      // Emoji
      tp.text = TextSpan(text: f.emoji, style: const TextStyle(fontSize: 22));
      tp.layout();
      tp.paint(canvas, Offset(f.x - tp.width / 2, f.y - tp.height));
    }
  }

  @override
  bool shouldRepaint(covariant _FloaterPainter oldDelegate) => true;
}
