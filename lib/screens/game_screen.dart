import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore/firestore_service.dart';
import '../widgets/bingo_board.dart';

class GameScreen extends StatelessWidget {
  final String gameId;
  final String teamId; // Current team ID
  final FirestoreService _firestoreService = FirestoreService.instance;

  GameScreen({required this.gameId, required this.teamId});

  final teamColors = {
    "Rebi": Colors.blue,
    "Dorka": Colors.green,
    "Vanda": Colors.red,
    "Barbi": Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: teamColors[teamId] ?? Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            Text("Csapat: $teamId"),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('games')
            .doc(gameId)
            .collection('teams')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Nem csatlakozott még egy csapat sem!"));
          }

          final teamDocs = snapshot.data!.docs;

          // Consolidate marks for all teams
          final consolidatedMarks = List.generate(
            25,
                (index) => teamDocs
                .map((doc) {
              final teamMarks = List<Map<String, dynamic>>.from(doc['marks']);
              return teamMarks[index];
            })
                .toList(),
          );

          final board = List.generate(
            5,
                (i) {
              final boardData = List<String>.from(teamDocs.first['board'] ?? []);
              if (boardData.length < 25) {
                print("Invalid Tábla adatok: $boardData");
                throw Exception("Tábla adat nem tartalmaz elég elemet");
              }
              return boardData.sublist(i * 5, (i + 1) * 5);
            },
          );


          return BingoBoard(
            board: board,
            marks: List.generate(
              5,
                  (i) => consolidatedMarks.sublist(i * 5, (i + 1) * 5),
            ),
            teamColors: teamColors,
            onMarkCell: (row, col) async {
              try {
                await _firestoreService.updateMarks(gameId, teamId, row, col, mark: true);
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Nem sikerült megjelölni a cellát: $error")),
                );
              }
            },
            onUnmarkCell: (row, col) async {
              try {
                await _firestoreService.updateMarks(gameId, teamId, row, col, mark: false);
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to unmark cell: $error")),
                );
              }
            },
          );
        },
      ),
    );
  }
}