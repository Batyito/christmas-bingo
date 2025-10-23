import 'package:christmas_bingo/widgets/theme_effects/pastel_floaters_overlay.dart';
import 'package:christmas_bingo/widgets/theme_effects/twinkles_overlay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
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

class GameScreen extends StatefulWidget {
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

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? _poller;
  DocumentSnapshot<Map<String, dynamic>>? _gameDoc;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _teamDocs = const [];

  Color _hexToColor(String? hex) {
    if (hex == null) return Colors.grey;
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.windows) {
      _startPolling();
    }
  }

  void _startPolling() {
    // Initial fetch immediately, then poll.
    _fetchOnce();
    _poller = Timer.periodic(const Duration(milliseconds: 900), (_) {
      _fetchOnce();
    });
  }

  Future<void> _fetchOnce() async {
    try {
      final gameF = FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .get();
      final teamsF = FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .collection('teams')
          .get();
      final results = await Future.wait([gameF, teamsF]);
      if (!mounted) return;
      setState(() {
        _gameDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>?;
        _teamDocs = (results[1] as QuerySnapshot<Map<String, dynamic>>)
            .docs
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
      });
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('Game polling error: $e');
        return true;
      }());
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeKey = widget.currentThemeKey ?? _autoThemeKey();
    return Scaffold(
      appBar: GradientBlurAppBar(
        themeKey: themeKey,
        title: Row(
          children: [
            if (defaultTargetPlatform == TargetPlatform.windows)
              _TeamColorDotWindows(
                teamId: widget.teamId,
                teamDocs: _teamDocs,
                colorResolver: _hexToColor,
              )
            else
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('games')
                    .doc(widget.gameId)
                    .collection('teams')
                    .doc(widget.teamId)
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
              child: defaultTargetPlatform == TargetPlatform.windows
                  ? Builder(builder: (context) {
                      String title = "Csapat: ${widget.teamId}";
                      final data = _gameDoc?.data();
                      if (data != null && data['status'] == 'vége') {
                        title = "Nyertes: ${data['winner']}";
                      }
                      return Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    })
                  : StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('games')
                          .doc(widget.gameId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String title = "Csapat: ${widget.teamId}";
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
              effects: widget.effectsSettings,
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
            if (widget.effectsSettings.showSnow)
              const IgnorePointer(child: SnowfallOverlay()),
            if (widget.effectsSettings.showTwinkles)
              const IgnorePointer(child: TwinklesOverlay()),
          ],
          if (themeKey == 'easter') ...[
            if (widget.effectsSettings.showBunnies)
              const IgnorePointer(child: HoppingBunniesOverlay()),
            if (widget.effectsSettings.showFloaters)
              const IgnorePointer(child: PastelFloatersOverlay()),
          ],
          if (defaultTargetPlatform == TargetPlatform.windows)
            Builder(builder: (context) {
              if (_teamDocs.isEmpty) {
                return const Center(
                    child: Text("Nincsenek csapatok a játékban!"));
              }
              final teamDocs = _teamDocs;
              // Build consolidated marks across teams below; no need for per-team map here.

              // Extract board for the current team
              final currentTeamDoc = teamDocs.firstWhere(
                (doc) => doc.id == widget.teamId,
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
                  5, (i) => currentTeamBoard.sublist(i * 5, (i + 1) * 5));

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
                        final bool isCurrent = d.id == widget.teamId;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(isCurrent ? 0.3 : 0.18),
                            border: Border.all(
                                color: isCurrent
                                    ? Colors.white.withOpacity(0.9)
                                    : color.withOpacity(0.6),
                                width: isCurrent ? 2 : 1),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.35),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
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
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white
                                          .withOpacity(isCurrent ? 1 : 0.95))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: BingoBoard(
                      gameId: widget.gameId,
                      board: board,
                      marks: List.generate(
                        5,
                        (i) => consolidatedMarks.sublist(i * 5, (i + 1) * 5),
                      ),
                      teamColors: dynamicTeamColors,
                      onMarkCell: (row, col) async {
                        try {
                          final uid = AuthService().currentUser?.uid;
                          await widget._firestoreService.updateMarks(
                            widget.gameId,
                            widget.teamId,
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
                          await widget._firestoreService.updateMarks(
                            widget.gameId,
                            widget.teamId,
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
                      teamId: widget.teamId,
                    ),
                  )
                ],
              );
            })
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('games')
                  .doc(widget.gameId)
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
                  (doc) => doc.id == widget.teamId,
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
                      child: Row(
                        children: teamDocs.map((d) {
                          final color = dynamicTeamColors[d.id] ?? Colors.grey;
                          final bool isCurrent = d.id == widget.teamId;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(isCurrent ? 0.3 : 0.18),
                              border: Border.all(
                                  color: isCurrent
                                      ? Colors.white.withOpacity(0.9)
                                      : color.withOpacity(0.6),
                                  width: isCurrent ? 2 : 1),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.35),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
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
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white.withOpacity(
                                            isCurrent ? 1 : 0.95))),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Expanded(
                      child: BingoBoard(
                        gameId: widget.gameId,
                        board: board,
                        marks: List.generate(
                          5,
                          (i) => consolidatedMarks.sublist(i * 5, (i + 1) * 5),
                        ),
                        teamColors: dynamicTeamColors,
                        onMarkCell: (row, col) async {
                          try {
                            final uid = AuthService().currentUser?.uid;
                            await widget._firestoreService.updateMarks(
                              widget.gameId,
                              widget.teamId,
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
                            await widget._firestoreService.updateMarks(
                              widget.gameId,
                              widget.teamId,
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
                        teamId: widget.teamId,
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

class _TeamColorDotWindows extends StatelessWidget {
  final String teamId;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> teamDocs;
  final Color Function(String?) colorResolver;
  const _TeamColorDotWindows({
    required this.teamId,
    required this.teamDocs,
    required this.colorResolver,
  });

  @override
  Widget build(BuildContext context) {
    QueryDocumentSnapshot<Map<String, dynamic>>? doc;
    for (final d in teamDocs) {
      if (d.id == teamId) {
        doc = d;
        break;
      }
    }
    final Color color =
        doc != null ? colorResolver(doc['color']?.toString()) : Colors.grey;
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
