import 'package:flutter/material.dart';

import '../services/firestore/firestore_service.dart';
import '../models/bingo_item.dart';
import '../models/pack.dart';

class CreatePackScreen extends StatefulWidget {
  const CreatePackScreen({super.key});

  @override
  _CreatePackScreenState createState() => _CreatePackScreenState();
}

class _CreatePackScreenState extends State<CreatePackScreen> {
  final TextEditingController packNameController = TextEditingController();
  final TextEditingController itemController = TextEditingController();
  List<BingoItem> items = [];
  List<BingoItem> originalItems = [];
  List<Pack> packs = [];
  final FirestoreService _firestoreService = FirestoreService.instance;
  String? selectedPackId;
  bool isModified = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final loadedPacks = await _firestoreService.fetchPacks();
    setState(() {
      packs = loadedPacks;
    });
  }

  Pack? _getSelectedPack(String packId) {
    try {
      return packs.firstWhere((pack) => pack.id == packId);
    } catch (e) {
      return null;
    }
  }

  void _populateItemsFromPack(String packId) {
    final pack = _getSelectedPack(packId);
    if (pack != null) {
      setState(() {
        packNameController.text = pack.name;
        items = List.from(pack.items);
        originalItems = List.from(pack.items);
        isModified = false;
      });
    }
  }

  void _addItem(String content) {
    if (content.isNotEmpty) {
      setState(() {
        if (!items.any((item) => item.name == content)) {
          items.insert(0, BingoItem(name: content, level: 1)); // Add new item to the top
          isModified = true;
        }
        itemController.clear();
      });
    }
  }

  void _updateItemLevel(int index, int level) {
    setState(() {
      items[index] = items[index].copyWith(level: level); // Update item level
      isModified = true;

      // Move modified item to the top of the list
      final modifiedItem = items.removeAt(index);
      items.insert(0, modifiedItem);
    });
  }

  Future<void> _savePack() async {
    final packName = packNameController.text.trim();
    if (packName.isEmpty) {
      _showErrorDialog("Csomag neve nem lehet üres.");
      return;
    }

    final pack = Pack(
      id: packName.replaceAll(' ', '_').toLowerCase(),
      name: packName,
      items: items,
    );

    await _firestoreService.savePack(pack.id, pack);
    Navigator.pop(context);
  }

  Future<void> _updatePack() async {
    final pack = _getSelectedPack(selectedPackId!);
    if (pack != null) {
      final updatedPack = pack.copyWith(items: items);
      await _firestoreService.savePack(updatedPack.id, updatedPack);
      setState(() {
        originalItems = List.from(items); // Update the original items
        isModified = false; // Reset modification flag
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildPackDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedPackId,
      decoration: InputDecoration(
        labelText: "Csomag kiválasztása",
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
      dropdownColor: Theme.of(context).colorScheme.surface,
      iconEnabledColor: Theme.of(context).colorScheme.onSurface,
      onChanged: (value) {
        setState(() {
          selectedPackId = value;
          _populateItemsFromPack(value!);
        });
      },
      items: packs.map((pack) {
        return DropdownMenuItem<String>(
          value: pack.id,
          child: Text(
            pack.name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16.0,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemList() {
    return Expanded(
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final BingoItem item = items[index];
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
            trailing: DropdownButton<int>(
              value: item.level,
              onChanged: (level) {
                if (level != null) _updateItemLevel(index, level);
              },
              items: List.generate(
                5,
                    (level) => DropdownMenuItem<int>(
                  value: level + 1,
                  child: Text(
                    "Szint ${level + 1}",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface, // Matches theme
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),

            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Csomag Létrehozása",
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
            TextField(
              controller: packNameController,
              decoration: InputDecoration(
                labelText: "Csomag neve",
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: itemController,
                    decoration: InputDecoration(
                      labelText: "Tétel hozzáadása",
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _addItem(itemController.text),
                  child: const Text("Hozzáadás"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildItemList(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isModified
                  ? (selectedPackId != null ? _updatePack : _savePack)
                  : null,
              child: Text(selectedPackId != null ? "Csomag frissítése" : "Csomag mentése"),
            ),
          ],
        ),
      ),
    );
  }
}
