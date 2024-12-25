import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mami játékok")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              String gameId = "game_${DateTime.now().millisecondsSinceEpoch}";
              await _firestoreService.createGame(gameId, 5);
            },
            child: Text("Új játék"),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getGames(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final games = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return ListTile(
                      title: Text("Játék Azonositó: ${game['id']}"),
                      subtitle: Text("Status: ${game['status']}"),
                      onTap: () {
                        _selectTeam(context, game['id']);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectTeam(BuildContext context, String gameId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final teamNames = ["Rebi", "Dorka", "Vanda", "Barbi"];
        return ListView.builder(
          itemCount: teamNames.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(teamNames[index]),
              onTap: () {
                Navigator.pop(context); // Close the modal
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      gameId: gameId,
                      teamId: teamNames[index],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
