import 'package:flutter/material.dart';

/// A reusable glassy container with subtle border and translucent background.
///
/// Use this to keep a consistent look across screens. Tweaking bg/border opacity
/// lets you vary emphasis.
class GlassyPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double bgOpacity;
  final double borderOpacity;

  const GlassyPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 16,
    this.bgOpacity = 0.10,
    this.borderOpacity = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(borderOpacity)),
      ),
      child: child,
    );
  }
}
