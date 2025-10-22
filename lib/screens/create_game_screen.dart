import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:christmas_bingo/models/bingo_item.dart';
import 'package:christmas_bingo/models/pack.dart';
import '../services/firestore/firestore_service.dart';
import '../services/auth_service.dart';
import 'create_pack_screen.dart';
import '../widgets/quick_nav_sheet.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final FirestoreService _firestoreService = FirestoreService.instance;
  String? selectedPackId; // Store selected Pack ID
  List<Pack> packs = []; // Use Pack model
  String? gameId;
  final _teamControllers = List.generate(8, (_) => TextEditingController());
  bool _useFamilyTeams = false;
  List<String> _familyPackIds = [];

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    final loadedPacks = await _firestoreService.fetchPacks();
    if (!mounted) return;
    setState(() {
      packs = loadedPacks;
    });
  }

  Future<void> _prefillFromFamily() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final owned = await _firestoreService.getOwnedFamily(uid);
    final doc = owned;
    if (doc == null) return;
    _familyPackIds = List<String>.from(doc.data()?['packIds'] ?? []);
    final teamsSnap = await FirebaseFirestore.instance
        .collection('families')
        .doc(doc.id)
        .collection('teams')
        .orderBy('name')
        .get();
    final names =
        teamsSnap.docs.map((d) => d['name']?.toString() ?? '').toList();
    for (int i = 0; i < _teamControllers.length; i++) {
      _teamControllers[i].text = i < names.length ? names[i] : '';
    }
    setState(() {});
  }

  void _createGame() async {
    if (selectedPackId != null) {
      gameId = "game_${DateTime.now()}";
      final teams = _teamControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (teams.isEmpty) {
        teams.addAll(["Rebi", "Dorka", "Vanda", "Barbi"]);
      }
      final ownerId = AuthService().currentUser?.uid;
      // When using family teams, also pass team configs (colors and participants)
      List<Map<String, dynamic>>? teamConfigs;
      if (_useFamilyTeams) {
        final owned = await _firestoreService.getOwnedFamily(ownerId!);
        if (owned != null) {
          final snap = await FirebaseFirestore.instance
              .collection('families')
              .doc(owned.id)
              .collection('teams')
              .orderBy('name')
              .get();
          teamConfigs = snap.docs
              .map((d) => {
                    'name': d['name']?.toString() ?? '',
                    'color': d['color']?.toString(),
                    'participants': List<String>.from(d['participants'] ?? []),
                  })
              .toList();
        }
      }
      await _firestoreService.createGameWithPack(
        gameId!,
        selectedPackId!,
        teamNames: teams,
        ownerId: ownerId,
        teamConfigs: teamConfigs,
      );
      if (!mounted) return;
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
        actions: [
          IconButton(
            tooltip: 'Gyors menü',
            icon: const Icon(Icons.more_vert),
            onPressed: () => showQuickNavSheet(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPackDropdown(),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _useFamilyTeams,
                  onChanged: (v) async {
                    setState(() => _useFamilyTeams = v ?? false);
                    if (_useFamilyTeams) await _prefillFromFamily();
                  },
                ),
                const Text('Családi csapatok használata'),
              ],
            ),
            const SizedBox(height: 8),
            _buildTeamsEditor(),
            const SizedBox(height: 20),
            _buildActionButtons(context),
            const SizedBox(height: 20),
            _buildPackPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Csapatok', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(_teamControllers.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextField(
              controller: _teamControllers[i],
              decoration: InputDecoration(
                labelText: 'Csapat ${i + 1}',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPackDropdown() {
    final filtered = _useFamilyTeams && _familyPackIds.isNotEmpty
        ? packs.where((p) => _familyPackIds.contains(p.id)).toList()
        : packs;
    return DropdownButtonFormField<String>(
      initialValue: selectedPackId,
      decoration: InputDecoration(
        labelText: "Válassz egy csomagot",
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary, width: 1.5),
        ),
      ),
      dropdownColor: Theme.of(context).colorScheme.surface, // Matches theme
      iconEnabledColor:
          Theme.of(context).colorScheme.onSurface, // Styled to match theme
      onChanged: (value) => setState(() => selectedPackId = value),
      items: filtered.map<DropdownMenuItem<String>>((pack) {
        return DropdownMenuItem<String>(
          value: pack.id,
          child: Text(
            pack.name,
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.onSurface, // Ensures visibility
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
