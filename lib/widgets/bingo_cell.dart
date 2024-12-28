import 'package:flutter/material.dart';

class BingoCell extends StatelessWidget {
  final String content;
  final List<Map<String, dynamic>> marks; // Marks for this cell
  final Map<String, Color> teamColors; // Team colors
  final bool isMatching; // Whether this cell is part of a Bingo
  final String currentTeamId; // Current team ID

  const BingoCell({
    super.key,
    required this.content,
    required this.marks,
    required this.teamColors,
    required this.isMatching,
    required this.currentTeamId,
  });

  @override
  Widget build(BuildContext context) {
    // Assign colors to quadrants for marked teams
    final colors = _getQuadrantColors();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        border: Border.all(
          color: isMatching ? Colors.yellow : Colors.black,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: CustomPaint(
        painter: QuadrantPainter(
          colors: colors,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Text(
                  content,
                  style: TextStyle(
                    fontSize: _calculateFontSize(content, constraints),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: null,
                  softWrap: true,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Get the colors for each quadrant dynamically based on marks
  List<Color> _getQuadrantColors() {
    final defaultColor = Colors.transparent;

    return List.generate(4, (index) {
      if (index < marks.length &&
          marks[index]['marked'] == true &&
          marks[index].containsKey('teamId')) {
        final teamId = marks[index]['teamId']; // Access the teamId
        return teamColors[teamId] ?? defaultColor; // Use teamId for color
      }
      return defaultColor;
    });
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

class QuadrantPainter extends CustomPainter {
  final List<Color> colors;

  QuadrantPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final quadrants = [
      Rect.fromLTRB(0, 0, size.width / 2, size.height / 2), // Top-left
      Rect.fromLTRB(size.width / 2, 0, size.width, size.height / 2), // Top-right
      Rect.fromLTRB(0, size.height / 2, size.width / 2, size.height), // Bottom-left
      Rect.fromLTRB(size.width / 2, size.height / 2, size.width, size.height), // Bottom-right
    ];

    for (int i = 0; i < quadrants.length; i++) {
      paint.color = i < colors.length ? colors[i] : Colors.transparent;
      canvas.drawRect(quadrants[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
