part of 'firestore_service.dart';

extension TeamService on FirestoreService {
  Future<void> addTeam(
      String gameId, String teamId, Color teamColor, String teamName) async {
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
      // Store ARGB as hex string explicitly
      'teamColor': teamColor.toARGB32().toRadixString(16),
      'teamName': teamName,
    });
  }

  Future<void> updateMarks(String gameId, String teamId, int row, int col,
      {required bool mark, String? uid}) async {
    final teamDoc =
        _db.collection('games').doc(gameId).collection('teams').doc(teamId);

    await _db.runTransaction((transaction) async {
      final teamSnapshot = await transaction.get(teamDoc);

      if (!teamSnapshot.exists) {
        throw Exception("Team not found");
      }

      final marks = List<Map<String, dynamic>>.from(teamSnapshot['marks']);
      final markIndex = row * 5 + col;

      marks[markIndex]['marked'] = mark;

      transaction.update(teamDoc, {'marks': marks});
      // Update game's last played timestamp
      transaction.update(_db.collection('games').doc(gameId), {
        'lastPlayedAt': FieldValue.serverTimestamp(),
      });
    });
    // Increment user tilesMarked and lastPlayedAt (outside transaction)
    if (uid != null && mark) {
      try {
        await incrementUserStat(uid, 'tilesMarked', 1);
        await _db.collection('users').doc(uid).update({
          'lastPlayedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
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
          List<Map<String, dynamic>>.from(doc.data()['marks'] ?? [])
              .map((mark) {
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

  Future<void> joinTeamByCode(
      {required String joinCode, required String uid}) async {
    final query = await _db
        .collectionGroup('teams')
        .where('joinCode', isEqualTo: joinCode)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw Exception('Invalid join code');
    }
    final doc = query.docs.first.reference;
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) throw Exception('Team not found');
      final members = List<String>.from(snap.data()!['members'] ?? []);
      if (members.contains(uid)) return;
      if (members.length >= 4) {
        throw Exception('A csapat betelt (max 4 fő).');
      }
      tx.update(doc, {
        'members': FieldValue.arrayUnion([uid])
      });
    });
    // increment user's gamesPlayed
    try {
      await incrementUserStat(uid, 'gamesPlayed', 1);
    } catch (_) {}
  }

  Future<Map<String, String>> findTeamByJoinCode(String joinCode) async {
    final query = await _db
        .collectionGroup('teams')
        .where('joinCode', isEqualTo: joinCode)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw Exception('Invalid join code');
    }
    final doc = query.docs.first;
    final teamId = doc.id;
    final gameId = doc.reference.parent.parent!.id;
    return {'gameId': gameId, 'teamId': teamId};
  }

  Stream<List<Map<String, String>>> streamUserTeams(String uid) {
    return _db
        .collectionGroup('teams')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final teamId = d.id;
              final gameId = d.reference.parent.parent!.id;
              final name = d.data()['name']?.toString() ?? teamId;
              return {
                'gameId': gameId,
                'teamId': teamId,
                'teamName': name,
              };
            }).toList());
  }
}
