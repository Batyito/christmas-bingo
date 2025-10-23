import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  // Number-only variant
  factory AppTextField.number({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    ValueChanged<String>? onChanged,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      enabled: enabled,
    );
  }

  // Multiline variant
  factory AppTextField.multiline({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    int maxLines = 4,
    ValueChanged<String>? onChanged,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
      onChanged: onChanged,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      enabled: enabled,
    );
  }

  // Search variant
  factory AppTextField.search({
    Key? key,
    TextEditingController? controller,
    String? hint,
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      hint: hint ?? 'Keresés…',
      onChanged: onChanged,
      prefixIcon: const Icon(Icons.search),
      enabled: enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      enabled: enabled,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.10),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}
