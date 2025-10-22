import 'package:flutter/material.dart';

import '../screens/create_game_screen.dart';
import '../screens/create_pack_screen.dart';
import '../screens/family_screen.dart';
import '../screens/join_game_screen.dart';
import '../screens/theme_settings_screen.dart';
import '../services/auth_service.dart';
import '../models/effects_settings.dart';

/// A reusable, tacky-modern bottom sheet for quick navigation/actions.
///
/// Call [showQuickNavSheet] from any screen to open it.
Future<void> showQuickNavSheet(
  BuildContext context, {
  String? currentThemeKey,
  EffectsSettings? effects,
}) async {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final surface = theme.colorScheme.surface.withOpacity(0.85);
      final border = theme.colorScheme.onSurface.withOpacity(0.12);
      // Bold style can be applied inline where needed; no separate local needed.

      void close() => Navigator.of(ctx).pop();

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Kezdőlap'),
                  onTap: () {
                    close();
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/', (r) => false);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Új Játék'),
                  onTap: () {
                    close();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CreateGameScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Csomagok'),
                  onTap: () {
                    close();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CreatePackScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.family_restroom_outlined),
                  title: const Text('Család'),
                  onTap: () {
                    close();
                    if (currentThemeKey != null && effects != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FamilyScreen(
                            currentThemeKey: currentThemeKey,
                            effectsSettings: effects,
                          ),
                        ),
                      );
                    } else {
                      // Fallback: go Home first where theme/effects are wired
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (r) => false);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Csatlakozás kóddal'),
                  onTap: () {
                    close();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JoinGameScreen()),
                    );
                  },
                ),
                const Divider(height: 8),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Téma és effektek'),
                  subtitle: currentThemeKey != null
                      ? Text('Aktív téma: $currentThemeKey')
                      : null,
                  onTap: () {
                    close();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ThemeSettingsScreen(
                          initial: effects ?? const EffectsSettings(),
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Profil'),
                  onTap: () {
                    close();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profil hamarosan…')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Kijelentkezés',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () async {
                    close();
                    await AuthService().signOut();
                    // Return to root; auth gate will show SignInScreen
                    // Using a microtask to ensure sheet is fully closed before navigation
                    Future.microtask(() {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (r) => false);
                    });
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    },
  );
}
