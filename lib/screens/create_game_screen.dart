import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:christmas_bingo/models/bingo_item.dart';
import 'package:christmas_bingo/models/pack.dart';
import '../services/firestore/firestore_service.dart';
import '../services/auth_service.dart';
import 'create_pack_screen.dart';
import '../widgets/gradient_blur_app_bar.dart';
import '../widgets/theme_effects/seasonal_gradient_background.dart';
import '../widgets/theme_effects/snowfall_overlay.dart';
import '../widgets/theme_effects/twinkles_overlay.dart';
import '../widgets/theme_effects/hopping_bunnies_overlay.dart';
import '../widgets/theme_effects/pastel_floaters_overlay.dart';
import '../widgets/quick_nav_sheet.dart';
import '../widgets/glassy_panel.dart';

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
  bool _useFamilyTeams = false;
  List<String> _familyPackIds = [];
  String? _selectedFamilyId;
  List<_TeamDraft> _teams = [];
  List<String> _memberUids = [];
  Map<String, String> _displayNames = {}; // uid -> display name
  late final String _themeKey = _autoThemeKey();
  final List<TextEditingController> _nameControllers = [];

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

  Future<void> _loadFamiliesAndMaybeSelect() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    // Prefer owned family, else first membership
    final owned = await _firestoreService.getOwnedFamily(uid);
    DocumentSnapshot<Map<String, dynamic>>? familyDoc = owned;
    if (familyDoc == null) {
      final membership = await FirebaseFirestore.instance
          .collection('families')
          .where('members', arrayContains: uid)
          .limit(1)
          .get();
      if (membership.docs.isNotEmpty) familyDoc = membership.docs.first;
    }
    if (familyDoc != null) {
      _selectedFamilyId = familyDoc.id;
      _familyPackIds = List<String>.from(familyDoc.data()?['packIds'] ?? []);
      await _loadFamilyTeamsAndMembers(familyDoc.id);
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadFamilyTeamsAndMembers(String familyId) async {
    // Load members
    final fam = await FirebaseFirestore.instance
        .collection('families')
        .doc(familyId)
        .get();
    _memberUids = List<String>.from(fam.data()?['members'] ?? []);
    await _loadDisplayNames(_memberUids);
    // Load teams -> drafts
    final teamsSnap = await FirebaseFirestore.instance
        .collection('families')
        .doc(familyId)
        .collection('teams')
        .orderBy('name')
        .get();
    _teams = teamsSnap.docs
        .map((d) => _TeamDraft(
              name: (d['name']?.toString() ?? ''),
              colorHex: d['color']?.toString(),
              participants: List<String>.from(d['participants'] ?? []),
            ))
        .toList();
    _syncNameControllersWithTeams();
  }

  Future<void> _loadDisplayNames(List<String> uids) async {
    _displayNames = {};
    if (uids.isEmpty) return;
    // Chunk by 10
    for (int i = 0; i < uids.length; i += 10) {
      final chunk =
          uids.sublist(i, i + 10 > uids.length ? uids.length : i + 10);
      final users = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in users.docs) {
        _displayNames[d.id] = (d.data()['displayName']?.toString() ??
            d.data()['email']?.toString() ??
            d.id);
      }
    }
  }

  void _createGame() async {
    if (selectedPackId != null) {
      gameId = "game_${DateTime.now()}";
      List<String> teams;
      List<Map<String, dynamic>>? teamConfigs;
      if (_teams.isNotEmpty) {
        teams = _teams
            .map((t) => t.name.trim().isEmpty ? 'Csapat' : t.name.trim())
            .toList();
        teamConfigs = _teams
            .map((t) => {
                  'name': t.name.trim().isEmpty ? 'Csapat' : t.name.trim(),
                  if (t.colorHex != null) 'color': t.colorHex,
                  'participants': t.participants.take(4).toList(),
                })
            .toList();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adj hozzá legalább egy csapatot!')),
        );
        return;
      }
      final ownerId = AuthService().currentUser?.uid;
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

  void _syncNameControllersWithTeams() {
    while (_nameControllers.length > _teams.length) {
      _nameControllers.removeLast().dispose();
    }
    for (var i = 0; i < _teams.length; i++) {
      if (i >= _nameControllers.length) {
        _nameControllers.add(TextEditingController(text: _teams[i].name));
      } else {
        final c = _nameControllers[i];
        if (c.text != _teams[i].name) c.text = _teams[i].name;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientBlurAppBar(
        themeKey: _themeKey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
      body: Stack(
        children: [
          SeasonalGradientBackground(themeKey: _themeKey),
          if (_themeKey == 'christmas') ...[
            const IgnorePointer(child: SnowfallOverlay()),
            const IgnorePointer(child: TwinklesOverlay()),
          ] else ...[
            const IgnorePointer(child: HoppingBunniesOverlay()),
            const IgnorePointer(child: PastelFloatersOverlay()),
          ],
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Config panel
                    Expanded(
                      flex: 2,
                      child: _buildConfigPanel(context),
                    ),
                    const SizedBox(width: 16),
                    // Right: Pack preview
                    Expanded(
                      flex: 2,
                      child: _buildPackPreview(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigPanel(BuildContext context) {
    return GlassyPanel(
      padding: const EdgeInsets.all(16),
      bgOpacity: 0.14,
      borderOpacity: 0.12,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPackDropdown(),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: _useFamilyTeams,
              title: const Text('Családi csapatok használata'),
              onChanged: (v) async {
                setState(() => _useFamilyTeams = v);
                if (v) await _loadFamiliesAndMaybeSelect();
              },
            ),
            if (_useFamilyTeams) ...[
              _buildFamilySelector(),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            const Text('Csapatok (max 8)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._teams
                .asMap()
                .entries
                .map((e) => _buildTeamEditor(context, e.key, e.value)),
            if (_teams.length < 8)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _teams.add(_TeamDraft(name: 'Csapat ${_teams.length + 1}'));
                  });
                  _syncNameControllersWithTeams();
                },
                icon: const Icon(Icons.add),
                label: const Text('Csapat hozzáadása'),
              ),
            const SizedBox(height: 12),
            _buildActionButtons(context),
          ],
        ),
      ),
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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: const Text(
          "Válassz egy csomagot a bal oldali panelen.",
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    final pack = _getSelectedPack(selectedPackId!);
    if (pack == null || pack.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: const Text(
          "Nincs megjeleníthető elem a kiválasztott csomagban.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return GlassyPanel(
      padding: const EdgeInsets.all(16),
      bgOpacity: 0.10,
      borderOpacity: 0.08,
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
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final BingoItem item = pack.items[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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

  Widget _buildFamilySelector() {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('families')
          .where('members', arrayContains: AuthService().currentUser?.uid)
          .get(),
      builder: (context, snap) {
        final families = snap.data?.docs ?? const [];
        if (families.isEmpty) {
          return const Text('Nincs elérhető család.');
        }
        return DropdownButtonFormField<String>(
          value: _selectedFamilyId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Válassz családot',
            border: OutlineInputBorder(),
          ),
          items: families
              .map((d) => DropdownMenuItem<String>(
                    value: d.id,
                    child: Text(d['name']?.toString() ?? d.id),
                  ))
              .toList(),
          onChanged: (id) async {
            setState(() => _selectedFamilyId = id);
            if (id != null) {
              final fam = families.firstWhere((e) => e.id == id);
              _familyPackIds = List<String>.from(fam.data()['packIds'] ?? []);
              await _loadFamilyTeamsAndMembers(id);
              setState(() {});
            }
          },
        );
      },
    );
  }

  Widget _buildTeamEditor(BuildContext context, int index, _TeamDraft draft) {
    const palette = <Color>[
      Color(0xFFE57373),
      Color(0xFF64B5F6),
      Color(0xFF81C784),
      Color(0xFFFFB74D),
      Color(0xFFBA68C8),
      Color(0xFF4DB6AC),
      Color(0xFFA1887F),
      Color(0xFFFF8A65),
    ];
    return GlassyPanel(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      bgOpacity: 0.10,
      borderOpacity: 0.12,
      radius: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Csapat neve'),
                  controller: _nameControllers.length > index
                      ? _nameControllers[index]
                      : null,
                  onChanged: (v) => draft.name = v,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<Color>(
                value: _resolveColor(draft.colorHex) ??
                    palette[index % palette.length],
                onChanged: (c) {
                  setState(() {
                    draft.colorHex = _colorToHex(c!);
                  });
                },
                items: palette
                    .map((c) => DropdownMenuItem<Color>(
                          value: c,
                          child: Container(width: 24, height: 24, color: c),
                        ))
                    .toList(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() {
                    _teams.removeAt(index);
                    if (_nameControllers.length > index) {
                      _nameControllers[index].dispose();
                      _nameControllers.removeAt(index);
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Résztvevők (max 4)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _memberUids.map((uid) {
              final selected = draft.participants.contains(uid);
              final label = _displayNames[uid] ?? uid.substring(0, 6);
              return FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (sel) {
                  setState(() {
                    if (sel) {
                      if (draft.participants.length < 4) {
                        draft.participants.add(uid);
                      }
                    } else {
                      draft.participants.remove(uid);
                    }
                  });
                },
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  static String _colorToHex(Color c) =>
      c.value.toRadixString(16).padLeft(8, '0').toUpperCase();
  static Color? _resolveColor(String? hex) {
    if (hex == null) return null;
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }

  String _autoThemeKey() {
    final month = DateTime.now().month;
    return (month == 10 || month == 11 || month == 12 || month == 1)
        ? 'christmas'
        : 'easter';
  }
}

class _TeamDraft {
  String name;
  String? colorHex;
  List<String> participants;

  _TeamDraft({
    required this.name,
    this.colorHex,
    List<String>? participants,
  }) : participants = participants ?? [];
}
