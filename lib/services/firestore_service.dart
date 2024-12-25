import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new game
  Future<void> createGame(String gameId, int boardSize) async {
    List<String> bingoItems = await _fetchOrInitializeBingoItems();

    await FirebaseFirestore.instance.collection('games').doc(gameId).set({
      'id': gameId,
      'bingoPool': bingoItems,
      'boardSize': boardSize,
      'status': 'folyamatban',
      'winner': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Initialize teams for the game
    await initializeTeamsForGame(gameId, bingoItems);
  }

  Future<void> joinGame(String gameId, String teamId, String teamName, Color teamColor) async {
    await addTeam(gameId, teamId, teamColor, teamName);
  }
  Stream<QuerySnapshot> getTeams(String gameId) {
    return FirebaseFirestore.instance
        .collection('games')
        .doc(gameId)
        .collection('teams')
        .snapshots();
  }

  Future<void> addTeam(String gameId, String teamId, Color teamColor, String teamName) async {
    List<String> bingoItems = await FirebaseFirestore.instance
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

    await FirebaseFirestore.instance
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







  // Get all games
  Stream<QuerySnapshot> getGames() {
    return _db.collection('games').snapshots();
  }

  // Create a team
  Future<void> createTeam(String teamId, String gameId, List<String> board) async {
    // Initialize marks as a flat list
    List<Map<String, dynamic>> marks = List.generate(
      25,
          (index) => {'row': index ~/ 5, 'col': index % 5, 'marked': false},
    );

    await _db.collection('teams').doc(teamId).set({
      'id': teamId,
      'gameID': gameId,
      'board': board,
      'marks': marks, // Add marks
      'members': [],
      'score': 0,
    });
  }


  // Update marks for a team
  Future<void> updateMarks(String gameId, String teamId, int row, int col, {required bool mark}) async {
    final teamDoc = FirebaseFirestore.instance
        .collection('games')
        .doc(gameId)
        .collection('teams')
        .doc(teamId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final teamSnapshot = await transaction.get(teamDoc);

      if (!teamSnapshot.exists) {
        throw Exception("Team not found");
      }

      final marks = List<Map<String, dynamic>>.from(teamSnapshot['marks']);
      final markIndex = row * 5 + col;

      // Update the specific cell for this team
      marks[markIndex]['marked'] = mark;

      // Update Firestore
      transaction.update(teamDoc, {'marks': marks});
    });
  }






  // Check game status
  Future<void> updateGameStatus(String gameId, String winnerTeamId) async {
    await _db.collection('games').doc(gameId).update({
      'status': 'finished',
      'winner': winnerTeamId,
    });
  }

  Future<DocumentSnapshot> getTeam(String teamId) async {
    return await FirebaseFirestore.instance.collection('teams').doc(teamId).get();
  }

  Stream<DocumentSnapshot> listenToTeam(String teamId) {
    return FirebaseFirestore.instance.collection('teams').doc(teamId).snapshots();
  }

  Future<void> initializeBingoBoard(String gameId, String teamId, List<String> bingoItems) async {
    bingoItems.shuffle();
    List<String> flatBoard = bingoItems.take(25).toList();

    List<Map<String, dynamic>> marks = List.generate(
      25,
          (index) => {'row': index ~/ 5, 'col': index % 5, 'marked': false, 'teamId': teamId},
    );

    DocumentReference teamDoc = FirebaseFirestore.instance
        .collection('games')
        .doc(gameId)
        .collection('teams')
        .doc(teamId);

    final docSnapshot = await teamDoc.get();

    if (docSnapshot.exists) {
      await teamDoc.update({
        'board': flatBoard,
        'marks': marks,
      });
    } else {
      await teamDoc.set({
        'board': flatBoard,
        'marks': marks,
        'gameId': gameId,
        'teamId': teamId,
      });
    }
  }




  Future<void> initializeTeamsForGame(String gameId, List<String> bingoItems) async {
    // Ensure enough items are available for at least one board
    if (bingoItems.length < 25) {
      throw Exception("Not enough Bingo items to initialize a board. At least 25 items are required.");
    }

    // Shuffle the items once for randomness
    bingoItems.shuffle();

    final teams = ['Rebi', 'Dorka', 'Vanda', 'Barbi'];
    final teamsCollection = FirebaseFirestore.instance
        .collection('games')
        .doc(gameId)
        .collection('teams');

    for (String team in teams) {
      // Select 25 items for the team, reshuffling to ensure unique positioning
      final teamItems = List.of(bingoItems)..shuffle();
      final boardItems = teamItems.take(25).toList();

      // Initialize marks for the 5x5 grid
      final marks = List.generate(
        25,
            (index) => {'row': index ~/ 5, 'col': index % 5, 'marked': false, 'teamId': team},
      );

      await teamsCollection.doc(team).set({
        'teamId': team,
        'board': boardItems, // 25 unique items for the team
        'marks': marks,
      });
    }
  }







  Future<void> saveBingoItems(List<String> items) async {
    await FirebaseFirestore.instance.collection('settings').doc('bingoItems').set({
      'items': items,
    });
  }
  Future<List<String>> getBingoItems() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('bingoItems').get();
    if (doc.exists && doc.data() != null) {
      return List<String>.from(doc.data()!['items']);
    }
    throw Exception("Bingo items not found.");
  }
  Future<List<String>> _fetchOrInitializeBingoItems() async {
    final docRef = FirebaseFirestore.instance.collection('settings').doc('bingoItems');

    // Check if the document exists
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      // Return the existing items
      return List<String>.from(docSnapshot.data()!['items']);
    } else {
      // Define the basic dataset
      final List<String> defaultItems = [
        "Katák🫠", "Ági 🍕", "Szelfi 🤳", "Kaja fotó 📸🥙", "Mexikó 🇲🇽",
        "Dávid orvosi kérdések 👨‍⚕️😷", "Boldi és Zoé 🤨", "Dobos Mikulás 🎅",
        "\"Nem kellett volna\" 🤭", "Mama törött kezei ✋", "\"Jaj maradj már\" 😠",
        "Zoli eszi meg Zoé maradékát🍞", "Zoli lever valamit 💔", "Mami átöltözik 👗",
        "Petya síelés ⛷️", "Legfiatalabb bontja a pezsgőt 🍾", "Húzzuk arrébb az asztalt 🪑",
        "Ne vedd le a cipőt 👟", "\"Ti nem isztok?\" 🥃", "\"Papi hozd be kintről\"",
        "Timi kérdez mit, aztán nem figyel🥲", "Mami \"Mit kérsz?\" 🍗🍟🧆", "Zoli nyugdíj👴",
        "Boldi káromkodik 😱", "Rebi Sára lesz 🦄", "Zoli és Sára pillanat ❤️‍🔥",
        "\"Levike most nincs rántott hús\" 😢", "Rebi szemüveg 🤓", "\"Na\" 🫢",
        "Vanda új munka 💼", "Dorka munka/tanulás📚", "Timi egyetem 🎓",
        "Mikor fotózkodunk? 📷", "Mami kezébe ordító gyerek😭", "Koccintás fájl 🥂",
        "Zoli tölt 🫗", "\"Dávid ízlik?\" 🙄", "Egyél/egyetek még 🥗",
        "Utalás a gyerekre 👶🍼", "Minaret 🕌"
      ];

      // Save the basic dataset in Firestore
      await docRef.set({'items': defaultItems});

      // Return the default dataset
      return defaultItems;
    }
  }


}
