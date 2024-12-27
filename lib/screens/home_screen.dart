import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore/firestore_service.dart';
import 'game_screen.dart';
import 'create_game_screen.dart';

class HomeScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService.instance;
  final ValueChanged<String> onThemeChange; // Updated to accept string theme keys

  HomeScreen({super.key, required this.onThemeChange});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mami Játékok",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.palette),
            tooltip: "Téma választása",
            onSelected: onThemeChange,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "system",
                child: Text("Automatikus Téma"),
              ),
              const PopupMenuItem(
                value: "christmas",
                child: Text("Karácsonyi Téma"),
              ),
              const PopupMenuItem(
                value: "easter",
                child: Text("Húsvéti Téma"),
              ),
              const PopupMenuItem(
                value: "dark",
                child: Text("Dark Theme"),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCreateGameButton(context),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getGames(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final games = snapshot.data!.docs;

                  if (games.isEmpty) {
                    return const Center(
                      child: Text(
                        "Nincs játék létrehozva. Készíts egyet!",
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return _buildGamesList(games, context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateGameButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final gameId = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateGameScreen()),
        );
        if (gameId != null) {
          _selectTeam(context, gameId);
        }
      },
      icon: const Icon(Icons.add_circle_outline),
      label: const Text(
        "Új Játék",
        style: TextStyle(fontSize: 18),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildGamesList(List<QueryDocumentSnapshot> games, BuildContext context) {
    return ListView.separated(
      itemCount: games.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final game = games[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.videogame_asset, color: Colors.white),
            ),
            title: Text(
              "Játékazonosító: ${game['id']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Státusz: ${game['status']}",
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _selectTeam(context, game['id']);
            },
          ),
        );
      },
    );
  }

  void _selectTeam(BuildContext context, String gameId) {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      context: context,
      builder: (context) {
        final teamNames = ["Rebi", "Dorka", "Vanda", "Barbi"];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Válassz csapatot!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                itemCount: teamNames.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.group,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(teamNames[index]),
                      onTap: () {
                        Navigator.pop(context);
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
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
