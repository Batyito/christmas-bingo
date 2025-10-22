import 'package:christmas_bingo/widgets/theme_effects/pastel_floaters_overlay.dart';
import 'package:christmas_bingo/widgets/theme_effects/twinkles_overlay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/bingo_board.dart';
import '../widgets/bingo_rules_painter.dart';
import '../widgets/theme_effects/seasonal_gradient_background.dart';
import '../widgets/theme_effects/snowfall_overlay.dart';
import '../widgets/theme_effects/hopping_bunnies_overlay.dart';
import '../widgets/gradient_blur_app_bar.dart';
import '../models/effects_settings.dart';
import '../widgets/quick_nav_sheet.dart';

class GameScreen extends StatelessWidget {
  final String gameId;
  final String teamId; // Current team ID
  final FirestoreService _firestoreService = FirestoreService.instance;
  final String? currentThemeKey;
  final EffectsSettings effectsSettings;

  GameScreen({
    super.key,
    required this.gameId,
    required this.teamId,
    this.currentThemeKey,
    EffectsSettings? effectsSettings,
  }) : effectsSettings = effectsSettings ?? const EffectsSettings();

  Color _hexToColor(String? hex) {
    if (hex == null) return Colors.grey;
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeKey = currentThemeKey ?? _autoThemeKey();
    return Scaffold(
      appBar: GradientBlurAppBar(
        themeKey: themeKey,
        title: Row(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('games')
                  .doc(gameId)
                  .collection('teams')
                  .doc(teamId)
                  .snapshots(),
              builder: (context, snap) {
                final hex = snap.data?.data() is Map
                    ? ((snap.data!.data() as Map)['color']?.toString())
                    : null;
                final color = _hexToColor(hex);
                return Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('games')
                    .doc(gameId)
                    .snapshots(),
                builder: (context, snapshot) {
                  String title = "Csapat: $teamId";
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final gameData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    if (gameData['status'] == 'vége') {
                      title = "Nyertes: ${gameData['winner']}";
                    }
                  }
                  return Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Gyors menü',
            icon: const Icon(Icons.more_vert),
            onPressed: () => showQuickNavSheet(
              context,
              currentThemeKey: themeKey,
              effects: effectsSettings,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Játékszabályok"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Kattints egy cellára, hogy kijelöld, és hosszú nyomással törölheted a jelölést.",
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Bingót elérhetsz vízszintes, függőleges vagy átlós sorok kitöltésével. ",
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CustomPaint(
                          painter: BingoRulesPainter(),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Bezárás"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SeasonalGradientBackground(themeKey: themeKey),
          if (themeKey == 'christmas') ...[
            if (effectsSettings.showSnow)
              const IgnorePointer(child: SnowfallOverlay()),
            if (effectsSettings.showTwinkles)
              const IgnorePointer(child: TwinklesOverlay()),
          ],
          if (themeKey == 'easter') ...[
            if (effectsSettings.showBunnies)
              const IgnorePointer(child: HoppingBunniesOverlay()),
            if (effectsSettings.showFloaters)
              const IgnorePointer(child: PastelFloatersOverlay()),
          ],
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('games')
                .doc(gameId)
                .collection('teams')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text("Nincsenek csapatok a játékban!"));
              }

              final teamDocs = snapshot.data!.docs.toList()
                ..sort((a, b) => a.id.compareTo(b.id));
              // Build consolidated marks across teams below; no need for per-team map here.

              // Extract board for the current team
              final currentTeamDoc = teamDocs.firstWhere(
                (doc) => doc.id == teamId,
                orElse: () => throw Exception("Csapat nem található"),
              );

              final currentTeamBoard =
                  (currentTeamDoc['board'] as List<dynamic>).map((cell) {
                // Support both legacy boards (List<String>) and new boards (List<Map{name,level}>)
                if (cell is String) return cell;
                if (cell is Map && cell.containsKey('name')) {
                  return cell['name'] as String;
                }
                throw Exception("Hibás cellaadatok: $cell");
              }).toList();

              // Consolidate marks for all teams, defensive against short/missing mark lists
              Map<String, dynamic> _defaultMark(int idx) => {
                    'row': idx ~/ 5,
                    'col': idx % 5,
                    'marked': false,
                  };
              List<Map<String, dynamic>> _safeMarksForDoc(
                  QueryDocumentSnapshot doc) {
                final raw = doc.data() as Map<String, dynamic>;
                final list = List<Map<String, dynamic>>.from(
                    (raw['marks'] ?? const <Map<String, dynamic>>[]));
                // Pad/truncate to 25
                if (list.length < 25) {
                  return List.generate(
                      25,
                      (i) => i < list.length
                          ? {..._defaultMark(i), ...list[i]}
                          : _defaultMark(i));
                }
                return List.generate(
                    25, (i) => {..._defaultMark(i), ...list[i]});
              }

              final consolidatedMarks = List.generate(25, (index) {
                return teamDocs.map((doc) {
                  final marks = _safeMarksForDoc(doc);
                  return {
                    ...marks[index],
                    'teamId': doc.id,
                  };
                }).toList();
              });

              // Convert board to 5x5 grid
              final board = List.generate(
                5,
                (i) => currentTeamBoard.sublist(i * 5, (i + 1) * 5),
              );

              // Build dynamic teamColors map from stored hex colors
              final dynamicTeamColors = <String, Color>{
                for (final d in teamDocs)
                  d.id: _hexToColor(d['color']?.toString())
              };

              return Column(
                children: [
                  // Team legend
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Row(
                      children: teamDocs.map((d) {
                        final color = dynamicTeamColors[d.id] ?? Colors.grey;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.25),
                            border: Border.all(color: color.withOpacity(0.7)),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                              Text(d.id,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: BingoBoard(
                      gameId: gameId,
                      board: board,
                      marks: List.generate(
                        5,
                        (i) => consolidatedMarks.sublist(i * 5, (i + 1) * 5),
                      ),
                      teamColors: dynamicTeamColors,
                      onMarkCell: (row, col) async {
                        try {
                          final uid = AuthService().currentUser?.uid;
                          await _firestoreService.updateMarks(
                            gameId,
                            teamId,
                            row,
                            col,
                            mark: true,
                            uid: uid,
                          );
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Nem sikerült a cella kijelölése: $error")),
                          );
                        }
                      },
                      onUnmarkCell: (row, col) async {
                        try {
                          final uid = AuthService().currentUser?.uid;
                          await _firestoreService.updateMarks(
                            gameId,
                            teamId,
                            row,
                            col,
                            mark: false,
                            uid: uid,
                          );
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Nem sikerült a jelölés törlése: $error")),
                          );
                        }
                      },
                      teamId: teamId,
                    ),
                  )
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _autoThemeKey() {
    final month = DateTime.now().month;
    return (month == 10 || month == 11 || month == 12 || month == 1)
        ? 'christmas'
        : 'easter';
  }
}
