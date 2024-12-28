part of 'firestore_service.dart';

extension GameService on FirestoreService {

  Future<void> createGameWithPack(String gameId, String packId) async {
    final packDoc = await _db.collection('packs').doc(packId).get();
    if (!packDoc.exists) throw Exception("Pack not found");

    final pack = Pack.fromFirestore(packDoc);
    final bingoPool = pack.items.map((item) => item).toList();

    await _db.collection('games').doc(gameId).set({
      'id': gameId,
      'packId': packId,
      'bingoPool': bingoPool.map((item) => item.name).toList(), // Store names for reference
      'boardSize': 5,
      'status': 'folyamatban',
      'winner': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await initializeTeamsForGame(gameId, bingoPool);
  }

  Future<void> updateGameStatus(String gameId, String winnerTeamId) async {
    await _db.collection('games').doc(gameId).update({
      'status': 'finished',
      'winner': winnerTeamId,
    });
  }

  Stream<QuerySnapshot> getGames() {
    return _db.collection('games').snapshots();
  }

  Future<void> initializeTeamsForGame(String gameId, List<BingoItem> bingoPool) async {
    // Define level distribution for fair boards
    const levelDistribution = {
      1: 0.5,  // 50% Level 1
      2: 0.3,  // 30% Level 2
      3: 0.15, // 15% Level 3
      4: 0.025, // 2.5% Level 4
      5: 0.025, // 2.5% Level 5
    };

    final teams = ['Rebi', 'Dorka', 'Vanda', 'Barbi'];

    // Group items by levels
    final groupedItems = <int, List<BingoItem>>{};
    for (var item in bingoPool) {
      groupedItems.putIfAbsent(item.level, () => []).add(item);
    }

    for (var level in groupedItems.keys) {
      groupedItems[level]?.shuffle(); // Shuffle items within each level
    }

    for (String team in teams) {
      List<BingoItem> teamBoard = [];

      // Fill the board based on level distribution
      for (var level in levelDistribution.keys) {
        int desiredCount = (levelDistribution[level]! * 25).round();
        var availableItems = groupedItems[level] ?? [];

        if (availableItems.length >= desiredCount) {
          // Add desired count of items from this level
          teamBoard.addAll(availableItems.take(desiredCount));
        } else {
          // Add all available items if fewer than desired count
          teamBoard.addAll(availableItems);
        }
      }

      // Fill remaining slots if any (shouldn't happen with proper setup)
      while (teamBoard.length < 25) {
        teamBoard.add(bingoPool[teamBoard.length % bingoPool.length]);
      }

      teamBoard.shuffle(); // Shuffle the board for uniqueness in order

      await _db.collection('games').doc(gameId).collection('teams').doc(team).set({
        'name': team,
        'board': teamBoard.map((item) => item.toMap()).toList(),
        'marks': List.generate(25, (index) => {
          'row': index ~/ 5,
          'col': index % 5,
          'marked': false,
        }),
      });
    }
  }




  int _determineItemLevel(String itemName) {
    // Logic to determine the level of an item based on its name or other properties
    // Replace this with the actual implementation
    if (itemName.contains("easy")) return 1;
    if (itemName.contains("medium")) return 3;
    return 5; // Default to hardest level
  }

}
