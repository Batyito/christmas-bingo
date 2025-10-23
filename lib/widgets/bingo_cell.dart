import 'dart:math' as math;
import 'package:flutter/material.dart';

class BingoCell extends StatefulWidget {
  final String content;
  final List<Map<String, dynamic>> marks; // Marks for this cell
  final Map<String, Color> teamColors; // Team colors
  final bool isMatching; // Whether this cell is part of a Bingo
  final String currentTeamId; // Current team ID
  final List<String> teamOrder; // Stable team order for segment mapping

  const BingoCell({
    super.key,
    required this.content,
    required this.marks,
    required this.teamColors,
    required this.isMatching,
    required this.currentTeamId,
    required this.teamOrder,
  });

  @override
  State<BingoCell> createState() => _BingoCellState();
}

class _BingoCellState extends State<BingoCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _stampController;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  Set<String> _prevMarkedTeams = {};
  Set<String> _pulseTeams = {};

  @override
  void initState() {
    super.initState();
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_stampController);
    _opacity = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_stampController);
    _prevMarkedTeams = _markedTeams(widget.marks);
  }

  @override
  void didUpdateWidget(covariant BingoCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newMarked = _markedTeams(widget.marks);
    final added = newMarked.difference(_prevMarkedTeams);
    if (added.isNotEmpty) {
      _pulseTeams = added;
      _stampController.forward(from: 0);
    }
    _prevMarkedTeams = newMarked;
  }

  @override
  void dispose() {
    _stampController.dispose();
    super.dispose();
  }

  Set<String> _markedTeams(List<Map<String, dynamic>> marks) {
    final set = <String>{};
    for (final m in marks) {
      if (m['marked'] == true && m['teamId'] != null) {
        set.add(m['teamId'] as String);
      }
    }
    return set;
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors per segment according to team order
    final markedSet = _markedTeams(widget.marks);
    final segCount = widget.teamOrder.length.clamp(1, 12);
    final List<Color> segColors = List.generate(segCount, (i) {
      final teamId = i < widget.teamOrder.length ? widget.teamOrder[i] : null;
      if (teamId != null && markedSet.contains(teamId)) {
        return widget.teamColors[teamId]?.withOpacity(0.85) ?? Colors.black26;
      }
      return Colors.transparent;
    });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border.all(
          color: widget.isMatching
              ? Colors.yellow.withOpacity(0.9)
              : Colors.black.withOpacity(0.5),
          width: widget.isMatching ? 2.4 : 1.4,
        ),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          if (widget.isMatching)
            BoxShadow(
              color: Colors.yellow.withOpacity(0.35),
              blurRadius: 10,
              spreadRadius: 1,
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Segments painter
            AnimatedBuilder(
              animation: _stampController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _MultiSegmentPainter(
                    segColors: segColors,
                    segCount: segCount,
                    pulseTeams: _pulseTeams,
                    teamOrder: widget.teamOrder,
                    pulse: _stampController.value,
                  ),
                );
              },
            ),
            // Content text on top
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Text(
                      widget.content,
                      style: TextStyle(
                        fontSize:
                            _calculateFontSize(widget.content, constraints),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          )
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: null,
                      softWrap: true,
                    );
                  },
                ),
              ),
            ),
            // Stamp pop for current team
            if (_pulseTeams.contains(widget.currentTeamId))
              Center(
                child: FadeTransition(
                  opacity: _opacity,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Transform.rotate(
                      angle: -0.12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (widget.teamColors[widget.currentTeamId] ??
                                  Colors.white)
                              .withOpacity(0.15),
                          border: Border.all(
                            color: (widget.teamColors[widget.currentTeamId] ??
                                    Colors.white)
                                .withOpacity(0.9),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'STAMP',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _calculateFontSize(String text, BoxConstraints constraints) {
    double baseSize = (constraints.maxWidth + constraints.maxHeight) / 9.5;
    int textLength = text.length;
    if (textLength > 20) {
      baseSize *= 0.7;
    } else if (textLength > 40) {
      baseSize *= 0.5;
    }
    return baseSize.clamp(12.0, 50.0);
  }
}

class _MultiSegmentPainter extends CustomPainter {
  final List<Color> segColors;
  final int segCount;
  final Set<String> pulseTeams;
  final List<String> teamOrder;
  final double pulse; // 0..1

  _MultiSegmentPainter({
    required this.segColors,
    required this.segCount,
    required this.pulseTeams,
    required this.teamOrder,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final radius = math.min(w, h) / 2;

    if (segCount <= 1) return;

    if (segCount == 2) {
      // Horizontal split: top / bottom
      final rects = [
        Rect.fromLTRB(0, 0, w, h / 2),
        Rect.fromLTRB(0, h / 2, w, h),
      ];
      for (int i = 0; i < 2; i++) {
        paint.color = i < segColors.length ? segColors[i] : Colors.transparent;
        if (paint.color.opacity > 0) canvas.drawRect(rects[i], paint);
      }
      _drawDividers(canvas, size, [Offset(0, h / 2), Offset(w, h / 2)]);
      return;
    }

    if (segCount == 4) {
      // Four quadrants
      final rects = [
        Rect.fromLTRB(0, 0, w / 2, h / 2),
        Rect.fromLTRB(w / 2, 0, w, h / 2),
        Rect.fromLTRB(0, h / 2, w / 2, h),
        Rect.fromLTRB(w / 2, h / 2, w, h),
      ];
      for (int i = 0; i < 4; i++) {
        paint.color = i < segColors.length ? segColors[i] : Colors.transparent;
        if (paint.color.opacity > 0) canvas.drawRect(rects[i], paint);
      }
      _drawDividers(canvas, size, [
        Offset(w / 2, 0),
        Offset(w / 2, h),
        Offset(0, h / 2),
        Offset(w, h / 2),
      ]);
      return;
    }

    // 3 (peace-like) and 5+ (star-like): draw wedge sectors
    final center = Offset(cx, cy);
    final ring = Rect.fromCircle(center: center, radius: radius);
    final int count = segCount;
    final double sweep = 2 * math.pi / count;
    double start = -math.pi / 2; // start at top
    for (int i = 0; i < count; i++) {
      final color = i < segColors.length ? segColors[i] : Colors.transparent;
      if (color.opacity > 0) {
        paint.color = color;
        final path = Path()
          ..moveTo(cx, cy)
          ..arcTo(ring, start, sweep, false)
          ..close();
        canvas.drawPath(path, paint);
      }
      start += sweep;
    }

    // Draw "peace" style divider lines for 3, and starry spokes for 5
    final divPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    if (segCount == 3 || segCount >= 5) {
      double a = -math.pi / 2;
      for (int i = 0; i < segCount; i++) {
        final dx = cx + radius * math.cos(a);
        final dy = cy + radius * math.sin(a);
        canvas.drawLine(center, Offset(dx, dy), divPaint);
        a += sweep;
      }
      canvas.drawCircle(
          center, radius, divPaint..color = divPaint.color.withOpacity(0.2));
    }

    // Pulse halo for newly marked teams
    if (pulse > 0.0 && pulseTeams.isNotEmpty) {
      final halo = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 * (1 - (pulse.clamp(0.0, 1.0)))
        ..color = Colors.white
            .withOpacity(0.20 * (1 - (pulse - 0.2).clamp(0.0, 1.0)));
      canvas.drawCircle(center, radius * (0.7 + 0.3 * pulse), halo);
    }
  }

  void _drawDividers(Canvas canvas, Size size, List<Offset> points) {
    final p = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < points.length; i += 2) {
      canvas.drawLine(points[i], points[i + 1], p);
    }
  }

  @override
  bool shouldRepaint(covariant _MultiSegmentPainter oldDelegate) {
    return oldDelegate.segColors != segColors ||
        oldDelegate.segCount != segCount ||
        oldDelegate.pulse != pulse ||
        oldDelegate.pulseTeams != pulseTeams;
  }
}
