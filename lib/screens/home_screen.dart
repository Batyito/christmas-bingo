import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore/firestore_service.dart';
import '../services/auth_service.dart';
import 'game_screen.dart';
import 'create_game_screen.dart';
import 'create_pack_screen.dart';
import 'family_screen.dart';
import '../widgets/theme_effects/snowfall_overlay.dart';
import '../widgets/theme_effects/hopping_bunnies_overlay.dart';
import '../widgets/theme_effects/seasonal_gradient_background.dart';
import '../widgets/theme_effects/twinkles_overlay.dart';
import '../widgets/theme_effects/pastel_floaters_overlay.dart';
import '../widgets/gradient_blur_app_bar.dart';
import '../models/effects_settings.dart';
import 'join_game_screen.dart';
import 'theme_settings_screen.dart';
import '../widgets/quick_nav_sheet.dart';
import '../widgets/glassy_panel.dart';

class HomeScreen extends StatelessWidget {
  // Optionally inject a service for testing; falls back to the singleton.
  final FirestoreService? firestoreService;
  final ValueChanged<String>
      onThemeChange; // Updated to accept string theme keys

  const HomeScreen(
      {super.key,
      required this.onThemeChange,
      required this.currentThemeKey,
      required this.effectsSettings,
      required this.onEffectsChanged,
      this.firestoreService});
  final String currentThemeKey;
  final EffectsSettings effectsSettings;
  final ValueChanged<EffectsSettings> onEffectsChanged;

  FirestoreService get _firestoreService =>
      firestoreService ?? FirestoreService.instance;
  AuthService get _auth => AuthService();

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
        title: const Text(
          "Mami Játékok",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: 'Gyors menü',
            icon: const Icon(Icons.more_vert),
            onPressed: () => showQuickNavSheet(
              context,
              currentThemeKey: currentThemeKey,
              effects: effectsSettings,
            ),
          ),
          IconButton(
            tooltip: 'Join game',
            icon: const Icon(Icons.login),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinGameScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Effects settings',
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.palette),
            tooltip: "Téma választása",
            onSelected: onThemeChange,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "system",
                child: Text("Automatikus Téma"),
              ),
              const PopupMenuItem(
                value: "christmas",
                child: Text("Karácsonyi Téma"),
              ),
              const PopupMenuItem(
                value: "easter",
                child: Text("Húsvéti Téma"),
              ),
              const PopupMenuItem(
                value: "dark",
                child: Text("Dark Theme"),
              ),
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
                Expanded(
                  child: _buildDashboard(context),
                )
              ],
            ),
          ),
          // Themed animated overlays
          if (currentThemeKey == 'christmas') ...[
            if (effectsSettings.showSnow)
              const IgnorePointer(child: SnowfallOverlay()),
            if (effectsSettings.showTwinkles)
              const IgnorePointer(child: TwinklesOverlay()),
          ],
          if (currentThemeKey == 'easter') ...[
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
                MaterialPageRoute(builder: (_) => CreatePackScreen()),
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
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _firestoreService.userDocStream(uid),
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
          child: StreamBuilder<QuerySnapshot>(
            stream: uid == null
                ? const Stream<QuerySnapshot>.empty()
                : _firestoreService.getGames(ownerId: uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Hiba a játékok betöltésekor'));
              }
              final games = snapshot.data?.docs ?? const [];
              if (games.isEmpty) {
                return const Center(child: Text('Még nincs saját játék.'));
              }
              return _buildGamesList(games, context);
            },
          ),
        ),
        const SizedBox(height: 16),
        Text('Csapatjaim', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<List<Map<String, String>>>(
          stream: uid == null
              ? const Stream.empty()
              : _firestoreService.streamUserTeams(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Text('Hiba a csapatok betöltésekor');
            }
            final teams = snapshot.data ?? const <Map<String, String>>[];
            if (teams.isEmpty) {
              return const Text('Nem vagy tagja egy csapatnak sem.');
            }
            return Column(
              children: teams.map((t) {
                return GlassyPanel(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
          child: StreamBuilder<QuerySnapshot>(
            stream: uid == null
                ? const Stream.empty()
                : FirebaseFirestore.instance
                    .collection('games')
                    .where('ownerId', isEqualTo: uid)
                    .orderBy('lastPlayedAt', descending: true)
                    .limit(5)
                    .snapshots(),
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
        final gameId = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateGameScreen()),
        );
        if (!context.mounted) return;
        if (gameId != null) {
          _selectTeam(context, gameId);
        }
      },
      icon: const Icon(Icons.add_circle_outline),
      label: const Text(
        "Új Játék",
        style: TextStyle(fontSize: 18),
      ),
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
        final status =
            game['status'] ?? 'N/A'; // Default value if 'status' is null
        final winner = game['winner'] ??
            'Nincs győztes'; // Default value if 'winner' is null

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
            title: Text(
              "Játékazonosító: ${game['id']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Státusz: $status",
                  style: const TextStyle(color: Colors.grey),
                ),
                if (status ==
                    'vége') // Display the winner only if the game is finished
                  Text(
                    "Győztes: $winner",
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _selectTeam(context, game['id']);
            },
          ),
        );
      },
    );
  }

  void _selectTeam(BuildContext context, String gameId) {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      context: context,
      builder: (context) {
        final uid = _auth.currentUser?.uid;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('games')
                .doc(gameId)
                .collection('teams')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? const [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Ehhez a játékhoz még nincsenek csapatok.'),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Válassz csapatot!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...docs.map((d) {
                    final name = d.data()['name']?.toString() ?? d.id;
                    final colorHex = d.data()['color']?.toString();
                    final color = _hexToColor(colorHex);
                    final members =
                        List<String>.from(d.data()['members'] ?? []);
                    final isFull = members.length >= 4;
                    final isMember = uid != null && members.contains(uid);
                    return GlassyPanel(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: color),
                        title: Text(name),
                        subtitle: Text(isFull
                            ? 'Betelt (4/4)'
                            : 'Helyek: ${members.length}/4'),
                        trailing: isMember
                            ? const Icon(Icons.check, color: Colors.green)
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
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GameScreen(
                                  gameId: gameId,
                                  teamId: d.id,
                                  currentThemeKey: currentThemeKey,
                                  effectsSettings: effectsSettings,
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Color _hexToColor(String? hex) {
    if (hex == null) return Colors.grey;
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}
