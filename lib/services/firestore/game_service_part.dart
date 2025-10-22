part of 'firestore_service.dart';

extension GameService on FirestoreService {
  Future<void> createGameWithPack(
    String gameId,
    String packId, {
    List<String>? teamNames,
    String? ownerId,
    List<Map<String, dynamic>>?
        teamConfigs, // optional: [{name,color,participants}]
  }) async {
    final packDoc = await _db.collection('packs').doc(packId).get();
    if (!packDoc.exists) throw Exception("Pack not found");

    final pack = Pack.fromFirestore(packDoc);
    // Expand bingo pool based on 'times'
    final List<BingoItem> bingoPool = [];
    for (final item in pack.items) {
      final t = item.times <= 0 ? 1 : item.times;
      for (int i = 0; i < t; i++) {
        bingoPool.add(item);
      }
    }

    await _db.collection('games').doc(gameId).set({
      'id': gameId,
      'packId': packId,
      'ownerId': ownerId,
      'shareCode': _generateShareCode(),
      'bingoPool': bingoPool
          .map((item) => item.name)
          .toList(), // Store names for reference
      'boardSize': 5,
      'status': 'folyamatban',
      'winner': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment owner stats
    if (ownerId != null && ownerId.isNotEmpty) {
      try {
        await incrementUserStat(ownerId, 'gamesOwned', 1);
      } catch (_) {}
    }

    await initializeTeamsForGame(
      gameId,
      bingoPool,
      teams: (teamNames == null || teamNames.isEmpty)
          ? const ['Csapat 1']
          : teamNames,
      teamConfigs: teamConfigs,
    );
  }

  Future<void> updateGameStatus(String gameId, String winnerTeamId) async {
    try {
      // Fetch the current game status
      final gameSnapshot = await _db.collection('games').doc(gameId).get();
      final gameData = gameSnapshot.data();

      if (gameData != null && gameData['status'] != 'finished') {
        // If no winner, mark the current team as the winner
        await _db.collection('games').doc(gameId).update({
          'status': 'vége',
          'winner': winnerTeamId,
        });
        // Increment wins for winner team members
        try {
          final teamRef = _db
              .collection('games')
              .doc(gameId)
              .collection('teams')
              .doc(winnerTeamId);
          final teamSnap = await teamRef.get();
          final members = List<String>.from(teamSnap.data()?['members'] ?? []);
          for (final uid in members) {
            await incrementUserStat(uid, 'gamesWon', 1);
          }
        } catch (_) {}
        if (kDebugMode) {
          print("Game status updated: $winnerTeamId is the winner!");
        }
      } else {
        if (kDebugMode) {
          print("Game already finished or no data found.");
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print("Failed to update game status: $error");
      }
    }
  }

  Stream<QuerySnapshot> getGames({String? ownerId}) {
    final col = _db.collection('games');
    if (ownerId != null) {
      return col.where('ownerId', isEqualTo: ownerId).snapshots();
    }
    return col.snapshots();
  }

  Future<void> initializeTeamsForGame(
    String gameId,
    List<BingoItem> bingoPool, {
    required List<String> teams,
    List<Map<String, dynamic>>? teamConfigs,
  }) async {
    // Define level distribution for fair boards
    const levelDistribution = {
      1: 0.5, // 50% Level 1
      2: 0.3, // 30% Level 2
      3: 0.15, // 15% Level 3
      4: 0.025, // 2.5% Level 4
      5: 0.025, // 2.5% Level 5
    };

    // teams provided by caller

    // Group items by levels
    final groupedItems = <int, List<BingoItem>>{};
    for (var item in bingoPool) {
      groupedItems.putIfAbsent(item.level, () => []).add(item);
    }

    for (var level in groupedItems.keys) {
      groupedItems[level]?.shuffle(); // Shuffle items within each level
    }

    // Helper to score a board by difficulty sum
    int score(List<BingoItem> items) => items.fold(0, (s, i) => s + i.level);

    // Target counts per level per board
    final targetCounts = {
      for (final e in levelDistribution.entries) e.key: (e.value * 25).round(),
    };

    List<BingoItem> drawBoard() {
      final List<BingoItem> board = [];
      final local = {
        for (final e in groupedItems.entries) e.key: [...e.value]
      };
      for (final entry in targetCounts.entries) {
        final lvl = entry.key;
        final count = entry.value;
        final pool = local[lvl] ?? [];
        pool.shuffle();
        final take = count.clamp(0, pool.length);
        board.addAll(pool.take(take));
      }
      // Fill remaining from all levels combined
      final all = groupedItems.values.expand((e) => e).toList()..shuffle();
      while (board.length < 25 && all.isNotEmpty) {
        board.add(all.removeLast());
      }
      board.shuffle();
      return board.take(25).toList();
    }

    final Map<String, List<BingoItem>> boards = {
      for (final t in teams) t: drawBoard(),
    };
    // Simple refinement to reduce variance
    for (int iter = 0; iter < 6; iter++) {
      final entries = boards.entries.toList()
        ..sort((a, b) => score(a.value).compareTo(score(b.value)));
      final minScore = score(entries.first.value);
      final maxScore = score(entries.last.value);
      if (maxScore - minScore <= 4) break;
      boards[entries.last.key] = drawBoard();
    }

    // enforce max 8 teams
    final limitedTeams = teams.take(8).toList();
    for (int idx = 0; idx < limitedTeams.length; idx++) {
      final team = limitedTeams[idx];
      final cfg = teamConfigs != null && idx < teamConfigs.length
          ? teamConfigs[idx]
          : null;
      final colorHex = cfg?['color']?.toString();
      final participants =
          List<String>.from(cfg?['participants'] ?? const <String>[]);
      final teamBoard = boards[team] ?? drawBoard();
      await _db
          .collection('games')
          .doc(gameId)
          .collection('teams')
          .doc(team)
          .set({
        'name': team,
        'board': teamBoard.map((item) => item.toMap()).toList(),
        'marks': List.generate(
            25,
            (index) => {
                  'row': index ~/ 5,
                  'col': index % 5,
                  'marked': false,
                }),
        'members': participants.take(4).toList(),
        'participants': participants.take(4).toList(),
        if (colorHex != null) 'color': colorHex,
        'joinCode': _generateJoinCode(),
      });
    }
  }

  String _generateJoinCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    int seed = DateTime.now().microsecondsSinceEpoch;
    return List.generate(6, (i) {
      seed = 1664525 * seed + 1013904223; // LCG
      return alphabet[seed % alphabet.length];
    }).join();
  }

  String _generateShareCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    int seed = DateTime.now().millisecondsSinceEpoch;
    return List.generate(8, (i) {
      seed = 1103515245 * seed + 12345; // LCG
      return alphabet[seed % alphabet.length];
    }).join();
  }
}
