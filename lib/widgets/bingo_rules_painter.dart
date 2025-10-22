import 'package:flutter/material.dart';

class BingoRulesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    final linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0;

    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Calculate cell size
    double cellWidth = size.width / 5;
    double cellHeight = size.height / 5;

    // Draw the grid
    for (int i = 1; i < 5; i++) {
      // Horizontal lines
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        gridPaint,
      );
      // Vertical lines
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        gridPaint,
      );
    }

    // Draw the outer border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );

    // Draw red lines
    // Horizontal line (through the middle of the 2nd row)
    canvas.drawLine(
      Offset(0, 1.5 * cellHeight), // Middle of the 2nd row
      Offset(size.width, 1.5 * cellHeight),
      linePaint,
    );

    // Vertical line (through the middle of the 4th column)
    canvas.drawLine(
      Offset(3.5 * cellWidth, 0), // Middle of the 4th column
      Offset(3.5 * cellWidth, size.height),
      linePaint,
    );

    // Diagonal line
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
