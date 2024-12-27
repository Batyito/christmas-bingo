part of 'firestore_service.dart';

extension GameService on FirestoreService {
  Future<void> createGame(String gameId, int boardSize) async {
    List<String> bingoItems = await _fetchOrInitializeBingoItems();

    await _db.collection('games').doc(gameId).set({
      'id': gameId,
      'bingoPool': bingoItems,
      'boardSize': boardSize,
      'status': 'folyamatban',
      'winner': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await initializeTeamsForGame(gameId, bingoItems);
  }

  Future<void> createGameWithPack(String gameId, String packId) async {
    final packDoc = await _db.collection('packs').doc(packId).get();
    if (!packDoc.exists) throw Exception("Pack not found");

    final pack = Pack.fromFirestore(packDoc);
    final bingoPool = pack.items.map((item) => item.name).toList()..shuffle();

    await _db.collection('games').doc(gameId).set({
      'id': gameId,
      'packId': packId,
      'bingoPool': bingoPool,
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

  Future<void> initializeTeamsForGame(String gameId, List<String> bingoPool) async {
    final teams = ['Rebi', 'Dorka', 'Vanda', 'Barbi'];

    for (String team in teams) {
      final teamBoard = (List.of(bingoPool)..shuffle()).take(25).toList();

      await _db.collection('games').doc(gameId).collection('teams').doc(team).set({
        'name': team,
        'board': teamBoard,
        'marks': List.generate(25, (index) => {
          'row': index ~/ 5,
          'col': index % 5,
          'marked': false,
        }),
      });
    }
  }
}
