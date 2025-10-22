import 'package:flutter/material.dart';

import '../services/firestore/firestore_service.dart';
import '../models/bingo_item.dart';
import '../models/pack.dart';
import '../widgets/quick_nav_sheet.dart';

class CreatePackScreen extends StatefulWidget {
  const CreatePackScreen({super.key});

  @override
  State<CreatePackScreen> createState() => _CreatePackScreenState();
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
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final loadedPacks = await _firestoreService.fetchPacks();
    if (!mounted) return;
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
          items.insert(
              0,
              BingoItem(
                name: content,
                level: 1,
                times: 1,
              )); // Add new item to the top
          isModified = true;
        }
        itemController.clear();
      });
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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

  void _updateItemTimes(int index, int delta) {
    final current = items[index].times;
    final next = (current + delta).clamp(1, 9);
    setState(() {
      items[index] = items[index].copyWith(times: next);
      isModified = true;
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
      isModified = true;
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
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _updatePack() async {
    final pack = _getSelectedPack(selectedPackId!);
    if (pack != null) {
      final updatedPack = pack.copyWith(items: items);
      await _firestoreService.savePack(updatedPack.id, updatedPack);
      if (!mounted) return;
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
      initialValue: selectedPackId,
      decoration: InputDecoration(
        labelText: "Csomag kiválasztása",
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
      child: ReorderableListView.builder(
        scrollController: _scroll,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = items.removeAt(oldIndex);
            items.insert(newIndex, item);
            isModified = true;
          });
        },
        itemCount: items.length,
        itemBuilder: (context, index) {
          final BingoItem item = items[index];
          return Card(
            key: ValueKey(item.name),
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  Text("Szint: ${item.level}  •  Ismétlés: ${item.times}x"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Level picker
                  DropdownButton<int>(
                    value: item.level,
                    onChanged: (level) {
                      if (level != null) _updateItemLevel(index, level);
                    },
                    items: List.generate(
                      5,
                      (level) => DropdownMenuItem<int>(
                        value: level + 1,
                        child: Text("Szint ${level + 1}"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Times stepper
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Kevesebb',
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _updateItemTimes(index, -1),
                        ),
                        Text('${item.times}x'),
                        IconButton(
                          tooltip: 'Több',
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _updateItemTimes(index, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Eltávolítás',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeItem(index),
                  ),
                ],
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
                ElevatedButton.icon(
                  onPressed: () => _addItem(itemController.text),
                  icon: const Icon(Icons.add),
                  label: const Text("Hozzáadás"),
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
              child: Text(selectedPackId != null
                  ? "Csomag frissítése"
                  : "Csomag mentése"),
            ),
          ],
        ),
      ),
    );
  }
}
