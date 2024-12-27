// TeamColorPicker
import 'package:flutter/material.dart';

class TeamColorPicker extends StatelessWidget {
  final Function(Color) onColorPicked;

  const TeamColorPicker({super.key, required this.onColorPicked});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () => onColorPicked(color),
          child: Container(
            margin: EdgeInsets.all(8),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      }).toList(),
    );
  }
}