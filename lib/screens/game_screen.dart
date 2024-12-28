import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore/firestore_service.dart';
import '../widgets/bingo_board.dart';

class GameScreen extends StatelessWidget {
  final String gameId;
  final String teamId; // Current team ID
  final FirestoreService _firestoreService = FirestoreService.instance;

  GameScreen({super.key, required this.gameId, required this.teamId});

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
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: teamColors[teamId] ?? Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              "Csapat: $teamId",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
            return const Center(child: Text("No teams have joined yet!"));
          }

          final teamDocs = snapshot.data!.docs;
          final marksByTeam = Map<String, List<Map<String, dynamic>>>.fromEntries(
            snapshot.data!.docs.map((doc) {
              return MapEntry(
                doc.id,
                List<Map<String, dynamic>>.from(doc['marks']),
              );
            }),
          );

          debugPrint("Updated Marks from Firestore: $marksByTeam");
          // Extract board for the current team
          final currentTeamDoc = teamDocs.firstWhere(
                (doc) => doc.id == teamId,
            orElse: () => throw Exception("Team not found"),
          );

          final currentTeamBoard = (currentTeamDoc['board'] as List<dynamic>)
              .map((cell) {
            if (!cell.containsKey('name')) {
              throw Exception("Invalid cell data: $cell");
            }
            return cell['name'] as String;
          })
              .toList();

          // Consolidate marks for all teams
          final consolidatedMarks = List.generate(
            25,
                (index) => teamDocs.map((doc) {
              final teamId = doc.id; // Extract team ID
              final teamMarks = List<Map<String, dynamic>>.from(doc['marks']);

              // Add teamId to each mark
              return {
                ...teamMarks[index],
                'teamId': teamId, // Attach the teamId
              };
            }).toList(),
          );


          // Convert board to 5x5 grid
          final board = List.generate(
            5,
                (i) => currentTeamBoard.sublist(i * 5, (i + 1) * 5),
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
                  SnackBar(content: Text("Failed to mark cell: $error")),
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
            teamId: teamId,
          );
        },
      ),
    );
  }
}
