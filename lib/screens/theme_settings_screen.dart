import 'package:flutter/material.dart';
import '../models/effects_settings.dart';

class ThemeSettingsScreen extends StatefulWidget {
  final EffectsSettings initial;
  const ThemeSettingsScreen({super.key, required this.initial});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  late EffectsSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initial;
  }

  void _toggleSnow(bool value) =>
      setState(() => _settings = _settings.copyWith(showSnow: value));
  void _toggleTwinkles(bool value) =>
      setState(() => _settings = _settings.copyWith(showTwinkles: value));
  void _toggleBunnies(bool value) =>
      setState(() => _settings = _settings.copyWith(showBunnies: value));
  void _toggleFloaters(bool value) =>
      setState(() => _settings = _settings.copyWith(showFloaters: value));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Effects'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _settings),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Christmas'),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('Falling snow'),
            value: _settings.showSnow,
            onChanged: _toggleSnow,
            secondary: const Icon(Icons.ac_unit),
          ),
          SwitchListTile(
            title: const Text('Twinkles / sparkles'),
            value: _settings.showTwinkles,
            onChanged: _toggleTwinkles,
            secondary: const Icon(Icons.auto_awesome),
          ),
          const Divider(),
          const ListTile(
            title: Text('Easter'),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('Hopping bunnies'),
            value: _settings.showBunnies,
            onChanged: _toggleBunnies,
            secondary: const Icon(Icons.pets),
          ),
          SwitchListTile(
            title: const Text('Pastel floaters'),
            value: _settings.showFloaters,
            onChanged: _toggleFloaters,
            secondary: const Icon(Icons.egg_outlined),
          ),
        ],
      ),
    );
  }
}
