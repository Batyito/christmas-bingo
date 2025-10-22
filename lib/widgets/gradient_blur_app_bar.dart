import 'dart:ui';
import 'package:flutter/material.dart';

/// A prettier, seasonal header with a subtle blur and gradient tint.
class GradientBlurAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final String themeKey; // 'christmas' | 'easter' | other

  const GradientBlurAppBar({
    super.key,
    required this.title,
    required this.themeKey,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = _gradientForTheme(themeKey, scheme);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: leading,
      title: DefaultTextStyle.merge(
        style: const TextStyle(fontWeight: FontWeight.w700),
        child: title,
      ),
      actions: actions,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _gradientForTheme(String key, ColorScheme scheme) {
    // Use theme colors but soften with alpha for a glassy feel.
    final p = scheme.primary;
    final s = scheme.secondary;
    if (key == 'christmas') {
      return [
        p.withValues(alpha: 0.28),
        s.withValues(alpha: 0.20),
      ];
    } else if (key == 'easter') {
      return [
        p.withValues(alpha: 0.24),
        s.withValues(alpha: 0.22),
      ];
    } else {
      return [
        p.withValues(alpha: 0.20),
        s.withValues(alpha: 0.16),
      ];
    }
  }
}
