import 'package:flutter/material.dart';
import '../models/effects_settings.dart';
import '../widgets/theme_effects/seasonal_gradient_background.dart';
import '../widgets/theme_effects/snowfall_overlay.dart';
import '../widgets/theme_effects/twinkles_overlay.dart';
import '../widgets/theme_effects/hopping_bunnies_overlay.dart';
import '../widgets/theme_effects/pastel_floaters_overlay.dart';
import '../widgets/glassy_panel.dart';

class ThemeSettingsScreen extends StatefulWidget {
  final EffectsSettings initial;
  final String?
      themeKey; // current theme to preview ('christmas' | 'easter' | ...)
  const ThemeSettingsScreen({super.key, required this.initial, this.themeKey});

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
    final themeKey = widget.themeKey ?? 'christmas';
    return WillPopScope(
      onWillPop: () async {
        // Return the updated settings automatically when leaving the page.
        Navigator.pop(context, _settings);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Téma és effektek'),
        ),
        body: Stack(
          children: [
            // Background preview according to current theme
            SeasonalGradientBackground(themeKey: themeKey),

            // Overlays live-preview based on toggles
            if (themeKey == 'christmas') ...[
              if (_settings.showSnow)
                const IgnorePointer(child: SnowfallOverlay()),
              if (_settings.showTwinkles)
                const IgnorePointer(child: TwinklesOverlay()),
            ] else if (themeKey == 'easter') ...[
              if (_settings.showBunnies)
                const IgnorePointer(child: HoppingBunniesOverlay()),
              if (_settings.showFloaters)
                const IgnorePointer(child: PastelFloatersOverlay()),
            ],

            // Settings content in a glassy panel so animations are still visible behind
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: GlassyPanel(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                      Text('Előnézet',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'A beállítások azonnal érvényesülnek ezen az oldalon. Lépj vissza a mentéshez.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 16),
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Karácsony'),
                        dense: true,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hulló hópelyhek'),
                        value: _settings.showSnow,
                        onChanged: _toggleSnow,
                        secondary: const Icon(Icons.ac_unit),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Csillogások / szikrák'),
                        value: _settings.showTwinkles,
                        onChanged: _toggleTwinkles,
                        secondary: const Icon(Icons.auto_awesome),
                      ),
                      const Divider(),
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Húsvét'),
                        dense: true,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ugráló nyuszik'),
                        value: _settings.showBunnies,
                        onChanged: _toggleBunnies,
                        secondary: const Icon(Icons.pets),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Pasztell lebegők'),
                        value: _settings.showFloaters,
                        onChanged: _toggleFloaters,
                        secondary: const Icon(Icons.egg_outlined),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
