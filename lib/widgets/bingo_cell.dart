import 'package:flutter/material.dart';

class BingoCell extends StatelessWidget {
  final String content;
  final List<Map<String, dynamic>> marks; // List of marks for this cell
  final Map<String, Color> teamColors; // Colors for each team
  final bool isMatching; // Whether this cell is part of a Bingo

  const BingoCell({super.key,
    required this.content,
    required this.marks,
    required this.teamColors,
    required this.isMatching,
  });

  @override
  Widget build(BuildContext context) {
    // Determine which teams have marked this cell
    final markedTeams = marks
        .where((mark) => mark['marked'])
        .map((mark) => mark['teamId'])
        .toList();

    // Assign colors to quadrants based on marked teams
    final topLeftColor = markedTeams.isNotEmpty
        ? teamColors[markedTeams[0]] ?? Colors.transparent
        : Colors.transparent;
    final topRightColor = markedTeams.length > 1
        ? teamColors[markedTeams[1]] ?? Colors.transparent
        : Colors.transparent;
    final bottomLeftColor = markedTeams.length > 2
        ? teamColors[markedTeams[2]] ?? Colors.transparent
        : Colors.transparent;
    final bottomRightColor = markedTeams.length > 3
        ? teamColors[markedTeams[3]] ?? Colors.transparent
        : Colors.transparent;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        border: Border.all(
          color: isMatching ? Colors.yellow : Colors.black,
          width: 2,
        ),
      ),
      child: CustomPaint(
        painter: QuadrantPainter(
          topLeftColor: topLeftColor,
          topRightColor: topRightColor,
          bottomLeftColor: bottomLeftColor,
          bottomRightColor: bottomRightColor,
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
                  maxLines: null, // Allow unlimited lines
                  softWrap: true, // Enable text wrapping
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _calculateFontSize(String text, BoxConstraints constraints) {
    // Estimate font size based on cell dimensions and text length
    double baseSize = (constraints.maxWidth + constraints.maxHeight) / 9.5;
    int textLength = text.length;
    if (textLength > 20) {
      baseSize *= 0.7; // Reduce size for longer text
    } else if (textLength > 40) {
      baseSize *= 0.5; // Further reduce size for very long text
    }
    return baseSize.clamp(12.0, 50.0); // Clamp to a reasonable range
  }
}

class QuadrantPainter extends CustomPainter {
  final Color topLeftColor;
  final Color topRightColor;
  final Color bottomLeftColor;
  final Color bottomRightColor;

  QuadrantPainter({
    required this.topLeftColor,
    required this.topRightColor,
    required this.bottomLeftColor,
    required this.bottomRightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw top-left quadrant
    paint.color = topLeftColor;
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width / 2, size.height / 2),
      paint,
    );

    // Draw top-right quadrant
    paint.color = topRightColor;
    canvas.drawRect(
      Rect.fromLTRB(size.width / 2, 0, size.width, size.height / 2),
      paint,
    );

    // Draw bottom-left quadrant
    paint.color = bottomLeftColor;
    canvas.drawRect(
      Rect.fromLTRB(0, size.height / 2, size.width / 2, size.height),
      paint,
    );

    // Draw bottom-right quadrant
    paint.color = bottomRightColor;
    canvas.drawRect(
      Rect.fromLTRB(size.width / 2, size.height / 2, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
