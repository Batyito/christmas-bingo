import 'package:flutter/material.dart';

// Base button style factory to keep sizing and icon spacing consistent
ButtonStyle _baseButtonStyle(BuildContext context, ColorScheme scheme,
    {bool filled = true}) {
  final bg = filled ? scheme.primary : Colors.transparent;
  final fg = filled ? scheme.onPrimary : scheme.primary;
  final side = BorderSide(color: scheme.primary.withOpacity(0.8), width: 1.4);
  return ButtonStyle(
    minimumSize: WidgetStateProperty.all(const Size(48, 44)),
    padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
    backgroundColor: WidgetStateProperty.resolveWith((states) => filled
        ? (states.contains(WidgetState.disabled) ? bg.withOpacity(0.5) : bg)
        : null),
    foregroundColor: WidgetStateProperty.all(fg),
    overlayColor: WidgetStateProperty.all(fg.withOpacity(0.08)),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: filled ? BorderSide.none : side),
    ),
    side: WidgetStateProperty.all(filled ? BorderSide.none : side),
  );
}

class AppPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  const AppPrimaryButton(
      {super.key, required this.onPressed, required this.child, this.icon});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final button = ElevatedButton(
      style: _baseButtonStyle(context, scheme, filled: true),
      onPressed: onPressed,
      child: _ButtonChild(icon: icon, child: child),
    );
    return button;
  }
}

class AppSecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  const AppSecondaryButton(
      {super.key, required this.onPressed, required this.child, this.icon});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton.tonal(
      style: _baseButtonStyle(context, scheme, filled: true),
      onPressed: onPressed,
      child: _ButtonChild(icon: icon, child: child),
    );
  }
}

class AppOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  const AppOutlinedButton(
      {super.key, required this.onPressed, required this.child, this.icon});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      style: _baseButtonStyle(context, scheme, filled: false),
      onPressed: onPressed,
      child: _ButtonChild(icon: icon, child: child),
    );
  }
}

class _ButtonChild extends StatelessWidget {
  final IconData? icon;
  final Widget child;
  const _ButtonChild({required this.icon, required this.child});
  @override
  Widget build(BuildContext context) {
    if (icon == null) return child;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(child: child),
      ],
    );
  }
}
