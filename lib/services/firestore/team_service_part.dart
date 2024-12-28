part of 'firestore_service.dart';

extension TeamService on FirestoreService {
  Future<void> addTeam(String gameId, String teamId, Color teamColor, String teamName) async {
    List<String> bingoItems = await _db
        .collection('games')
        .doc(gameId)
        .get()
        .then((doc) => List<String>.from(doc.data()!['bingoPool']));

    bingoItems.shuffle();
    List<String> flatBoard = bingoItems.take(25).toList();

    List<Map<String, dynamic>> marks = List.generate(
      25,
          (index) => {'row': index ~/ 5, 'col': index % 5, 'marked': false},
    );

    await _db
        .collection('games')
        .doc(gameId)
        .collection('teams')
        .doc(teamId)
        .set({
      'board': flatBoard,
      'marks': marks,
      'teamColor': teamColor.value.toRadixString(16),
      'teamName': teamName,
    });
  }

  Future<void> updateMarks(String gameId, String teamId, int row, int col, {required bool mark}) async {
    final teamDoc = _db.collection('games').doc(gameId).collection('teams').doc(teamId);

    await _db.runTransaction((transaction) async {
      final teamSnapshot = await transaction.get(teamDoc);

      if (!teamSnapshot.exists) {
        throw Exception("Team not found");
      }

      final marks = List<Map<String, dynamic>>.from(teamSnapshot['marks']);
      final markIndex = row * 5 + col;

      marks[markIndex]['marked'] = mark;

      transaction.update(teamDoc, {'marks': marks});
    });
  }

  Stream<QuerySnapshot> getTeams(String gameId) {
    return _db.collection('games').doc(gameId).collection('teams').snapshots();
  }

  Stream<Map<String, List<Map<String, dynamic>>>> getTeamMarks(String gameId) {
    return FirebaseFirestore.instance
        .collection('games')
        .doc(gameId)
        .collection('teams')
        .snapshots()
        .map((snapshot) {
      return Map.fromEntries(snapshot.docs.map((doc) {
        return MapEntry(
          doc.id,
          List<Map<String, dynamic>>.from(doc.data()['marks'] ?? []).map((mark) {
            return {
              ...mark,
              'teamId': mark['teamId'] ?? doc.id, // Default to team ID
              'marked': mark['marked'] ?? false, // Default to false
            };
          }).toList(),
        );
      }));
    });
  }


}
