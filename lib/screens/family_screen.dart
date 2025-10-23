import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../core/utils/share_utils.dart';
import '../services/auth_service.dart';
import '../services/firestore/firestore_service.dart';
import '../models/pack.dart';
import '../models/effects_settings.dart';
import '../widgets/theme_effects/seasonal_gradient_background.dart';
import '../widgets/theme_effects/snowfall_overlay.dart';
import '../widgets/theme_effects/twinkles_overlay.dart';
import '../widgets/theme_effects/hopping_bunnies_overlay.dart';
import '../widgets/theme_effects/pastel_floaters_overlay.dart';
import '../widgets/gradient_blur_app_bar.dart';
// Removed drawer-specific screen imports; navigation now handled via quick_nav_sheet
import '../widgets/quick_nav_sheet.dart';
import '../shared/ui/inputs/app_text_field.dart';
import '../shared/ui/buttons/app_buttons.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen(
      {super.key,
      required this.currentThemeKey,
      required this.effectsSettings});

  final String currentThemeKey;
  final EffectsSettings effectsSettings;

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _auth = AuthService();
  final _fs = FirestoreService.instance;

  String? _familyId;
  String _familyName = '';
  final TextEditingController _familyNameController = TextEditingController();
  List<String> _memberUids = [];
  Map<String, String> _displayNames = {}; // uid -> displayName
  List<String> _packIds = [];
  List<Pack> _allPacks = [];
  // Multiple families support
  List<_FamilyLite> _families = [];

  final _inviteEmailController = TextEditingController();
  bool _creatingFamily = false;

  // Team editors state
  List<_TeamDraft> _teams = [];

  static const _palette = <Color>[
    Color(0xFFE57373),
    Color(0xFF64B5F6),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
    Color(0xFFBA68C8),
    Color(0xFF4DB6AC),
    Color(0xFFA1887F),
    Color(0xFFFF8A65),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inviteEmailController.dispose();
    _familyNameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    // load packs
    _allPacks = await _fs.fetchPacks();
    // Subscribe to all families where user is a member and keep local list
    _fs.streamFamiliesForUser(uid).listen((snap) async {
      _families = [
        for (final d in snap.docs)
          _FamilyLite(
              id: d.id, name: (d.data()['name'] ?? '').toString(), doc: d)
      ];
      // If current selection missing, pick first available, else keep selection
      if (_families.isEmpty) {
        _familyId = null;
        setState(() {});
        return;
      }
      final keep = _families.any((f) => f.id == _familyId);
      if (!keep) {
        _bindFamilyDoc(_families.first.doc);
      } else {
        setState(() {});
      }
    });
  }

  void _bindFamilyDoc(DocumentSnapshot<Map<String, dynamic>> doc) async {
    _familyId = doc.id;
    final data = doc.data() ?? {};
    _familyName = data['name']?.toString() ?? '';
    _memberUids = List<String>.from(data['members'] ?? []);
    _packIds = List<String>.from(data['packIds'] ?? []);
    await _loadDisplayNames();
    // load teams
    final teamsSnap = await FirebaseFirestore.instance
        .collection('families')
        .doc(_familyId)
        .collection('teams')
        .get();
    _teams = teamsSnap.docs.map((d) {
      final colorHex = d['color']?.toString();
      return _TeamDraft(
        id: d.id,
        name: d['name']?.toString() ?? '',
        colorHex: colorHex,
        participants: List<String>.from(d['participants'] ?? []),
      );
    }).toList();
    setState(() {});
  }

  Future<void> _loadDisplayNames() async {
    if (_memberUids.isEmpty) return;
    final col = FirebaseFirestore.instance.collection('users');
    final List<QuerySnapshot<Map<String, dynamic>>> snaps = [];
    const chunk = 10;
    for (var i = 0; i < _memberUids.length; i += chunk) {
      final ids = _memberUids.skip(i).take(chunk).toList();
      final s = await col.where(FieldPath.documentId, whereIn: ids).get();
      snaps.add(s);
    }
    final Map<String, String> out = {};
    for (final s in snaps) {
      for (final d in s.docs) {
        out[d.id] = (d.data()['displayName']?.toString() ??
            d.data()['email']?.toString() ??
            d.id);
      }
    }
    _displayNames = out;
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    return Scaffold(
      appBar: GradientBlurAppBar(
        themeKey: widget.currentThemeKey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Vissza',
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Család'),
            if (_familyName.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _familyName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Gyors menü',
            icon: const Icon(Icons.more_vert),
            onPressed: () => showQuickNavSheet(
              context,
              currentThemeKey: widget.currentThemeKey,
              effects: widget.effectsSettings,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SeasonalGradientBackground(themeKey: widget.currentThemeKey),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                _familyId == null ? _buildNoFamily(uid) : _buildManageFamily(),
          ),
          if (widget.currentThemeKey == 'christmas') ...[
            if (widget.effectsSettings.showSnow)
              const IgnorePointer(child: SnowfallOverlay()),
            if (widget.effectsSettings.showTwinkles)
              const IgnorePointer(child: TwinklesOverlay()),
          ],
          if (widget.currentThemeKey == 'easter') ...[
            if (widget.effectsSettings.showBunnies)
              const IgnorePointer(child: HoppingBunniesOverlay()),
            if (widget.effectsSettings.showFloaters)
              const IgnorePointer(child: PastelFloatersOverlay()),
          ],
        ],
      ),
    );
  }

  Widget _buildNoFamily(String? uid) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [
                  Icon(Icons.family_restroom, size: 20),
                  SizedBox(width: 8),
                  Text('Családok',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                const Text(
                    'Még nem vagy egy család tagja. Hozz létre egyet vagy csatlakozz kóddal.'),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _familyNameController,
                  label: 'Család neve',
                  hint: 'Pl. Mamiék',
                  maxLength: 40,
                  onChanged: (v) => setState(() => _familyName = v),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: uid == null ||
                              _familyName.trim().isEmpty ||
                              _creatingFamily
                          ? null
                          : () async {
                              setState(() => _creatingFamily = true);
                              try {
                                final id = await _fs.createFamily(
                                    name: _familyName.trim(), ownerId: uid);
                                final doc = await FirebaseFirestore.instance
                                    .collection('families')
                                    .doc(id)
                                    .get();
                                if (!mounted) return;
                                _bindFamilyDoc(doc);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Család létrehozva')));
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Hiba: $e')));
                              } finally {
                                if (mounted)
                                  setState(() => _creatingFamily = false);
                              }
                            },
                      icon: _creatingFamily
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_circle_outline),
                      label: const Text('Család létrehozása'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed:
                        uid == null ? null : () => _promptJoinByCode(uid),
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Csatlakozás kóddal'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManageFamily() {
    return ListView(
      children: [
        _panel(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.family_restroom),
                const SizedBox(width: 8),
                Expanded(child: _buildFamilySelector()),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _promptJoinByCode(_auth.currentUser!.uid),
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Csatlakozás'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  onPressed: _promptLeaveFamily,
                  icon: const Icon(Icons.logout),
                  label: const Text('Kilépés'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _familyId = null; // show create/join
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Új család'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _panel(
          child: ListTile(
            title: Text(_familyName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'Tagok: ${_memberUids.length}  |  Engedélyezett csomagok: ${_packIds.length}'),
          ),
        ),
        const SizedBox(height: 8),
        _buildInviteSection(),
        const SizedBox(height: 16),
        _buildPacksSection(),
        const SizedBox(height: 16),
        _buildTeamsSection(),
      ],
    );
  }

  Widget _buildFamilySelector() {
    return DropdownButton<String>(
      isExpanded: true,
      value: _familyId,
      hint: const Text('Válassz családot'),
      items: [
        for (final f in _families)
          DropdownMenuItem(
            value: f.id,
            child: Text(f.name.isEmpty ? '(Névtelen család)' : f.name),
          ),
      ],
      onChanged: (id) async {
        if (id == null) return;
        final doc = _families.firstWhere((f) => f.id == id).doc;
        _bindFamilyDoc(doc);
      },
    );
  }

  Future<void> _promptJoinByCode(String uid) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Csatlakozás meghívó kóddal'),
        content: AppTextField(
          controller: controller,
          label: 'Kód',
          hint: 'Pl. 9UKWDGPIH4',
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(12),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Mégse')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Csatlakozás')),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    try {
      final res = await _fs.acceptInviteWithCode(code: code, uid: uid);
      final famId = res['familyId'] as String?;
      if (famId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('families')
            .doc(famId)
            .get();
        if (!mounted) return;
        _bindFamilyDoc(doc);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Csatlakoztál a családhoz.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hiba: $e')));
    }
  }

  Widget _buildInviteSection() {
    return _panel(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Meghívás e-maillel',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _inviteEmailController,
                    label: 'E-mail cím',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final email = _inviteEmailController.text.trim();
                    if (email.isEmpty) return;
                    await _fs.inviteToFamily(
                        familyId: _familyId!, email: email);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Meghívó elküldve: $email')),
                      );
                    }
                    _inviteEmailController.clear();
                  },
                  child: const Text('Meghívás'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPacksSection() {
    return _panel(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Elérhető csomagok a családnak',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final p in _allPacks)
                  FilterChip(
                    label: Text(p.name),
                    selected: _packIds.contains(p.id),
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          _packIds.add(p.id);
                        } else {
                          _packIds.remove(p.id);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  await _fs.setFamilyPacks(
                      familyId: _familyId!, packIds: _packIds);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Csomagok frissítve')),
                    );
                  }
                },
                child: const Text('Mentés'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsSection() {
    return _panel(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Csapatok (max 8)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._teams
                .asMap()
                .entries
                .map((e) => _buildTeamEditor(e.key, e.value)),
            if (_teams.length < 8)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _teams.add(_TeamDraft(name: 'Csapat ${_teams.length + 1}'));
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Csapat hozzáadása'),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  // Upsert teams and delete removed ones while keeping IDs stable
                  final col = FirebaseFirestore.instance
                      .collection('families')
                      .doc(_familyId)
                      .collection('teams');
                  final existing = await col.get();
                  final keepIds = _teams
                      .where((t) => t.id != null)
                      .map((t) => t.id)
                      .toSet();
                  for (final d in existing.docs) {
                    if (!keepIds.contains(d.id)) {
                      await d.reference.delete();
                    }
                  }
                  for (final t in _teams) {
                    final colorHex = t.colorHex ??
                        _colorToHex(
                            _palette[(_teams.indexOf(t)) % _palette.length]);
                    final data = {
                      'name': t.name.trim().isEmpty ? 'Csapat' : t.name.trim(),
                      'color': colorHex,
                      'participants': t.participants.take(4).toList(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    };
                    if (t.id == null) {
                      final newRef = col.doc();
                      await newRef.set({
                        ...data,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      t.id = newRef.id;
                    } else {
                      await col.doc(t.id).set(data, SetOptions(merge: true));
                    }
                  }
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Csapatok mentve')),
                    );
                  }
                },
                child: const Text('Csapatok mentése'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTeamEditor(int index, _TeamDraft draft) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Csapat neve',
                  controller: TextEditingController(text: draft.name),
                  onChanged: (v) => draft.name = v,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<Color>(
                value: _resolveColor(draft.colorHex) ??
                    _palette[index % _palette.length],
                onChanged: (c) {
                  setState(() {
                    draft.colorHex = _colorToHex(c!);
                  });
                },
                items: _palette
                    .map((c) => DropdownMenuItem<Color>(
                          value: c,
                          child: Container(width: 24, height: 24, color: c),
                        ))
                    .toList(),
              ),
              const SizedBox(width: 8),
              AppOutlinedButton(
                onPressed: _familyId == null
                    ? null
                    : () async {
                        if (draft.id == null) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Előbb mentsd a csapatokat, majd próbáld újra.')),
                            );
                          }
                          return;
                        }
                        // Create an invite and copy full link
                        final code = await _fs.createTeamInvite(
                          familyId: _familyId!,
                          teamId: draft.id!,
                          ttl: const Duration(days: 30),
                        );
                        final link = _buildInviteLink(code);
                        await ShareUtils.shareOrCopy(
                          context,
                          link,
                          subject: 'Meghívó link',
                          copyMessage: 'Meghívó link vágólapra másolva',
                        );
                        setState(() {
                          draft.inviteCode = code;
                        });
                      },
                icon: Icons.link,
                child: const Text('Link másolása'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() {
                    _teams.removeAt(index);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (draft.inviteCode != null)
            Row(
              children: [
                const Icon(Icons.vpn_key, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _buildInviteLink(draft.inviteCode!),
                    overflow: TextOverflow.ellipsis,
                  ),
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

  Widget _panel({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: child,
    );
  }

  Future<void> _promptLeaveFamily() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _familyId == null) return;
    // Quick owner check
    final fam = await FirebaseFirestore.instance
        .collection('families')
        .doc(_familyId)
        .get();
    final isOwner = (fam.data()?['ownerId']?.toString() == uid);
    if (isOwner) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nem hagyhatod el a családot'),
          content: const Text(
              'Te vagy a család tulajdonosa. Add át a tulajdonjogot, vagy töröld a családot, majd próbáld újra.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Értem')),
          ],
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Kilépés a családból'),
            content: const Text(
                'Biztosan kilépsz? Eltávolítunk a család tagjai közül és a csapatokból.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Mégse')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Kilépés')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      await _fs.leaveFamily(familyId: _familyId!, uid: uid);
      // After leaving, pick another family if any; otherwise show create/join
      final snap = await _fs.streamFamiliesForUser(uid).first;
      if (snap.docs.isNotEmpty) {
        _bindFamilyDoc(snap.docs.first);
      } else {
        setState(() {
          _familyId = null;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kiléptél a családból.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hiba: $e')));
    }
  }

  String _buildInviteLink(String code) {
    final base = Uri.base;
    final origin = base.origin;
    final path = base.path; // keep GH Pages subpath if any
    return '$origin$path#/invite?c=$code';
  }

  static String _colorToHex(Color c) =>
      c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  static Color? _resolveColor(String? hex) {
    if (hex == null) return null;
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }
}

class _TeamDraft {
  String? id;
  String name;
  String? colorHex;
  List<String> participants;
  String? inviteCode;
  _TeamDraft(
      {this.id, required this.name, this.colorHex, List<String>? participants})
      : participants = participants ?? [];
}

class _FamilyLite {
  final String id;
  final String name;
  final DocumentSnapshot<Map<String, dynamic>> doc;
  _FamilyLite({required this.id, required this.name, required this.doc});
}

// Uppercase text input formatter for invite/join codes
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
