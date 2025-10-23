import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/effects_settings.dart';
import '../widgets/gradient_blur_app_bar.dart';
import '../widgets/glassy_panel.dart';
import '../widgets/quick_nav_sheet.dart';
import '../widgets/theme_effects/seasonal_gradient_background.dart';
import '../widgets/theme_effects/snowfall_overlay.dart';
import '../widgets/theme_effects/twinkles_overlay.dart';
import '../widgets/theme_effects/hopping_bunnies_overlay.dart';
import '../widgets/theme_effects/pastel_floaters_overlay.dart';
import 'create_game_screen.dart';
import 'create_pack_screen.dart';
import 'family_screen.dart';
import 'game_screen.dart';
import 'theme_settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onThemeChange,
    required this.currentThemeKey,
    required this.effectsSettings,
    required this.onEffectsChanged,
    this.firestoreService,
  });

  // Exposed for DI/testing
  final FirestoreService? firestoreService;

  // Theme and effects wiring
  final ValueChanged<String> onThemeChange;
  final String currentThemeKey;
  final EffectsSettings effectsSettings;
  final ValueChanged<EffectsSettings> onEffectsChanged;

  // Services
  AuthService get _auth => AuthService();
  FirestoreService get _firestoreService =>
      firestoreService ?? FirestoreService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientBlurAppBar(
        themeKey: currentThemeKey,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: currentThemeKey == 'christmas'
              ? const Text('🎄', style: TextStyle(fontSize: 22))
              : const Text('🐣', style: TextStyle(fontSize: 22)),
        ),
        title: const Text('Kezdőlap'),
        actions: [
          // Quick menu
          IconButton(
            tooltip: 'Gyors menü',
            icon: const Icon(Icons.more_vert),
            onPressed: () => showQuickNavSheet(
              context,
              currentThemeKey: currentThemeKey,
              effects: effectsSettings,
            ),
          ),
          // Effects settings
          IconButton(
            tooltip: 'Téma és effektek',
            icon: const Icon(Icons.tune),
            onPressed: () async {
              final updated = await Navigator.push<EffectsSettings>(
                context,
                MaterialPageRoute(
                  builder: (_) => ThemeSettingsScreen(initial: effectsSettings),
                ),
              );
              if (updated != null) {
                onEffectsChanged(updated);
              }
            },
          ),
          // Theme picker
          PopupMenuButton<String>(
            icon: const Icon(Icons.palette),
            tooltip: 'Téma választása',
            onSelected: onThemeChange,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'system', child: Text('Automatikus Téma')),
              PopupMenuItem(value: 'christmas', child: Text('Karácsonyi Téma')),
              PopupMenuItem(value: 'easter', child: Text('Húsvéti Téma')),
              PopupMenuItem(value: 'dark', child: Text('Dark Theme')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient background based on current theme
          SeasonalGradientBackground(themeKey: currentThemeKey),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopActions(context),
                const SizedBox(height: 16),
                Expanded(child: _buildDashboard(context)),
              ],
            ),
          ),
          // Themed animated overlays
          if (currentThemeKey == 'christmas') ...[
            if (effectsSettings.showSnow)
              const IgnorePointer(child: SnowfallOverlay()),
            if (effectsSettings.showTwinkles)
              const IgnorePointer(child: TwinklesOverlay()),
          ] else if (currentThemeKey == 'easter') ...[
            if (effectsSettings.showBunnies)
              const IgnorePointer(child: HoppingBunniesOverlay()),
            if (effectsSettings.showFloaters)
              const IgnorePointer(child: PastelFloatersOverlay()),
          ],
        ],
      ),
    );
  }

  Widget _buildTopActions(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCreateGameButton(context)),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePackScreen()),
              );
            },
            icon: const Icon(Icons.inventory_2),
            label: const Text('Csomagok'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FamilyScreen(
                    currentThemeKey: currentThemeKey,
                    effectsSettings: effectsSettings,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.family_restroom),
            label: const Text('Család'),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    return ListView(
      children: [
        if (uid != null)
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future:
                FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, snap) {
              final stats = (snap.data?.data()?['stats'] as Map?) ?? {};
              final lastPlayed = snap.data?.data()?['lastPlayedAt'];
              String lastPlayedText = '';
              if (lastPlayed is Timestamp) {
                final dt = lastPlayed.toDate();
                lastPlayedText = '  |  Utoljára játszva: ${dt.toLocal()}';
              }
              return GlassyPanel(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Statisztika',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Saját játékok: ${stats['gamesOwned'] ?? '-'}  |  Játszott: ${stats['gamesPlayed'] ?? '-'}  |  Győzelmek: ${stats['gamesWon'] ?? '-'}  |  Jelölt mezők: ${stats['tilesMarked'] ?? '-'}$lastPlayedText',
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        Text('Saját játékok', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: uid == null
              ? const Center(child: Text('Bejelentkezés szükséges.'))
              : FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('games')
                      .where('ownerId', isEqualTo: uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text('Hiba a játékok betöltésekor'));
                    }
                    final games = snapshot.data?.docs ?? const [];
                    if (games.isEmpty) {
                      return const Center(
                          child: Text('Még nincs saját játék.'));
                    }
                    return _buildGamesList(games, context);
                  },
                ),
        ),
        const SizedBox(height: 16),
        Text('Csapatjaim', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        uid == null
            ? const Text('Bejelentkezés szükséges a csapatok megjelenítéséhez.')
            : FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collectionGroup('teams')
                    .where('members', arrayContains: uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('Hiba a csapatok betöltésekor');
                  }
                  final docs = snapshot.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const Text('Nem vagy tagja egy csapatnak sem.');
                  }
                  final teams = docs.map((d) {
                    final data = d.data();
                    final teamId = d.id;
                    final gameId = d.reference.parent.parent!.id;
                    final name = data['name']?.toString() ?? teamId;
                    return {
                      'gameId': gameId,
                      'teamId': teamId,
                      'teamName': name
                    };
                  }).toList();
                  return Column(
                    children: teams.map((t) {
                      return GlassyPanel(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.group),
                          title: Text(t['teamName'] ?? t['teamId']!),
                          subtitle: Text('Játék: ${t['gameId']}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GameScreen(
                                  gameId: t['gameId']!,
                                  teamId: t['teamId']!,
                                  currentThemeKey: currentThemeKey,
                                  effectsSettings: effectsSettings,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
        const SizedBox(height: 16),
        Text('Legutóbbi saját játékok',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: uid == null
              ? const Center(child: Text('Bejelentkezés szükséges.'))
              : FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('games')
                      .where('ownerId', isEqualTo: uid)
                      .orderBy('lastPlayedAt', descending: true)
                      .limit(5)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text('Hiba az aktivitás betöltésekor'));
                    }
                    final games = snapshot.data?.docs ?? const [];
                    if (games.isEmpty) {
                      return const Center(child: Text('Még nincs aktivitás.'));
                    }
                    return _buildGamesList(games, context);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCreateGameButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final gameId = await Navigator.push<String?>(
          context,
          MaterialPageRoute(builder: (context) => const CreateGameScreen()),
        );
        if (!context.mounted) return;
        if (gameId != null) {
          _selectTeam(context, gameId);
        }
      },
      icon: const Icon(Icons.add_circle_outline),
      label: const Text('Új Játék', style: TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildGamesList(
      List<QueryDocumentSnapshot> games, BuildContext context) {
    return ListView.separated(
      itemCount: games.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final game = games[index];
        final status = game['status'] ?? 'N/A';
        final winner = game['winner'] ?? 'Nincs győztes';
        final gameId = (game.data() as Map<String, dynamic>?)?['id'] ?? game.id;

        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.videogame_asset, color: Colors.white),
            ),
            title: Text('Játékazonosító: $gameId',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Státusz: $status',
                    style: const TextStyle(color: Colors.grey)),
                if (status == 'vége') const SizedBox(height: 2),
                if (status == 'vége')
                  Text('Győztes: $winner',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectTeam(context, gameId),
          ),
        );
      },
    );
  }

  void _selectTeam(BuildContext context, String gameId) {
    final rootContext = context; // keep a stable context for navigation
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      context: context,
      builder: (sheetContext) {
        final uid = _auth.currentUser?.uid;
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.75,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('games')
                    .doc(gameId)
                    .collection('teams')
                    .get(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Hiba a csapatok betöltésekor'),
                    );
                  }
                  final docs = snap.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Ehhez a játékhoz még nincsenek csapatok.'),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Text('Válassz csapatot!',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final d = docs[i];
                            final data = d.data();
                            final name = data['name']?.toString() ?? d.id;
                            final colorHex = data['color']?.toString();
                            final color = _hexToColor(colorHex);
                            final members =
                                List<String>.from(data['members'] ?? []);
                            final isFull = members.length >= 4;
                            final isMember =
                                uid != null && members.contains(uid);
                            return GlassyPanel(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(backgroundColor: color),
                                title: Text(name),
                                subtitle: Text(isFull
                                    ? 'Betelt (4/4)'
                                    : 'Helyek: ${members.length}/4'),
                                trailing: isMember
                                    ? const Icon(Icons.check,
                                        color: Colors.green)
                                    : const Icon(Icons.chevron_right),
                                enabled: isMember || !isFull,
                                onTap: () async {
                                  try {
                                    if (!isMember && uid != null) {
                                      await _firestoreService.joinTeamBySelect(
                                        gameId: gameId,
                                        teamId: d.id,
                                        uid: uid,
                                      );
                                    }
                                    if (!sheetContext.mounted ||
                                        !rootContext.mounted) return;
                                    // Close the sheet first
                                    Navigator.pop(sheetContext);
                                    // Defer navigation to avoid racing with pop disposal
                                    Future.microtask(() {
                                      if (!rootContext.mounted) return;
                                      Navigator.push(
                                        rootContext,
                                        MaterialPageRoute(
                                          builder: (_) => GameScreen(
                                            gameId: gameId,
                                            teamId: d.id,
                                            currentThemeKey: currentThemeKey,
                                            effectsSettings: effectsSettings,
                                          ),
                                        ),
                                      );
                                    });
                                  } catch (e) {
                                    if (!rootContext.mounted) return;
                                    ScaffoldMessenger.of(rootContext)
                                        .showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Color _hexToColor(String? hex) {
    if (hex == null) return Colors.grey;
    try {
      var s = hex.trim().toLowerCase();
      if (s.startsWith('#')) s = s.substring(1);
      if (s.startsWith('0x')) s = s.substring(2);
      // If rgb only, add opaque alpha
      if (s.length == 6) s = 'ff$s';
      if (s.length != 8) {
        // try decimal form
        final dec = int.tryParse(hex);
        if (dec != null) return Color(dec);
      }
      final value = int.parse(s, radix: 16);
      return Color(value);
    } catch (_) {
      return Colors.grey;
    }
  }
}
