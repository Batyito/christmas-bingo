import 'package:flutter/material.dart';
import 'package:christmas_bingo/models/bingo_item.dart';
import 'package:christmas_bingo/models/pack.dart';
import '../services/firestore/firestore_service.dart';
import 'create_pack_screen.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  _CreateGameScreenState createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final FirestoreService _firestoreService = FirestoreService.instance;
  String? selectedPackId; // Store selected Pack ID
  List<Pack> packs = []; // Use Pack model
  String? gameId;

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    final loadedPacks = await _firestoreService.fetchPacks();
    setState(() {
      packs = loadedPacks;
    });
  }

  void _createGame() async {
    if (selectedPackId != null) {
      gameId = "game_${DateTime.now().millisecondsSinceEpoch}";
      await _firestoreService.createGameWithPack(gameId!, selectedPackId!);
      Navigator.pop(context, gameId); // Return game ID to the previous screen
    }
  }

  Pack? _getSelectedPack(String packId) {
    try {
      return packs.firstWhere((pack) => pack.id == packId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Új Játék Létrehozása",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPackDropdown(),
            const SizedBox(height: 20),
            _buildActionButtons(context),
            const SizedBox(height: 20),
            _buildPackPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildPackDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedPackId,
      decoration: InputDecoration(
        labelText: "Válassz egy csomagot",
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 1.5),
        ),
      ),
      dropdownColor: Theme.of(context).colorScheme.surface, // Matches theme
      iconEnabledColor: Theme.of(context).colorScheme.onSurface, // Styled to match theme
      onChanged: (value) => setState(() => selectedPackId = value),
      items: packs.map<DropdownMenuItem<String>>((pack) {
        return DropdownMenuItem<String>(
          value: pack.id,
          child: Text(
            pack.name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, // Ensures visibility
              fontSize: 16.0,
            ),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _createGame,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("Játék Létrehozása"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreatePackScreen()),
              );
            },
            icon: const Icon(Icons.create),
            label: const Text("Csomag Létrehozása"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackPreview() {
    if (selectedPackId == null) {
      return const Text(
        "Válassz egy csomagot a fenti legördülő menüből.",
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }

    final pack = _getSelectedPack(selectedPackId!);
    if (pack == null || pack.items.isEmpty) {
      return const Center(
        child: Text(
          "Nincs megjeleníthető elem a kiválasztott csomagban.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Csomag előnézet: ${pack.name}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            "Összes elem: ${pack.items.length}",
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const Divider(thickness: 1.0),
          Expanded(
            child: ListView.separated(
              itemCount: pack.items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final BingoItem item = pack.items[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Text("Szint: ${item.level}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
