import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/utils/share_utils.dart';

import '../models/pack.dart';
import '../services/firestore/firestore_service.dart';
import '../widgets/gradient_blur_app_bar.dart';
import '../widgets/glassy_panel.dart';
import '../widgets/quick_nav_sheet.dart';
import '../widgets/theme_effects/seasonal_gradient_background.dart';
import '../widgets/theme_effects/snowfall_overlay.dart';
import '../widgets/theme_effects/twinkles_overlay.dart';
import '../widgets/theme_effects/hopping_bunnies_overlay.dart';
import '../widgets/theme_effects/pastel_floaters_overlay.dart';
import '../core/utils/text_utils.dart';
import '../shared/ui/voting/vote_row.dart';
import '../shared/ui/buttons/app_buttons.dart';

class CollaboratePackScreen extends StatefulWidget {
  final String? initialPackId;
  const CollaboratePackScreen({super.key, this.initialPackId});

  @override
  State<CollaboratePackScreen> createState() => _CollaboratePackScreenState();
}

class _CollaboratePackScreenState extends State<CollaboratePackScreen> {
  final _fs = FirestoreService.instance;
  final _proposalController = TextEditingController();
  final _scroll = ScrollController();

  List<Pack> _packs = [];
  String? _selectedPackId;
  String? _shareCode;
  bool _loading = true;
  bool _enabling = false;

  @override
  void initState() {
    super.initState();
    _load().then((_) async {
      // Preselect pack if provided via deep link
      if (widget.initialPackId != null && _packs.isNotEmpty) {
        final exists = _packs.any((p) => p.id == widget.initialPackId);
        if (exists) {
          await _onPackChanged(widget.initialPackId);
        }
      }
    });
  }

  Future<void> _load() async {
    final packs = await _fs.fetchPacks();
    if (!mounted) return;
    setState(() {
      _packs = packs;
      _loading = false;
    });
  }

  Future<void> _onPackChanged(String? id) async {
    setState(() {
      _selectedPackId = id;
      _shareCode = null;
    });
    if (id == null) return;
    try {
      final code = await _fs.getOrCreatePackContribCode(id);
      if (!mounted) return;
      setState(() => _shareCode = code);
      // Ensure existing pack items are present as proposals to allow voting on them
      await _seedProposalsFromExistingItems(id);
    } catch (_) {
      // ignore for now
    }
  }

  /// Seed proposals collection from existing pack items so collaborators can
  /// vote on items that already exist in the pack.
  Future<void> _seedProposalsFromExistingItems(String packId) async {
    try {
      final pack = _packs.firstWhere((p) => p.id == packId);
      // Read existing proposals to avoid duplicates
      final ps = await FirebaseFirestore.instance
          .collection('packs')
          .doc(packId)
          .collection('proposals')
          .get();
      final existing = <String>{
        for (final d in ps.docs)
          normalizeText((d.data()['name'] ?? '').toString()),
      };
      final batch = FirebaseFirestore.instance.batch();
      int toCreate = 0;
      for (final item in pack.items) {
        final n = normalizeText(item.name);
        if (n.isEmpty || existing.contains(n)) continue;
        final ref = FirebaseFirestore.instance
            .collection('packs')
            .doc(packId)
            .collection('proposals')
            .doc();
        batch.set(ref, {
          'name': item.name,
          'createdBy': 'seed-existing',
          'createdAt': FieldValue.serverTimestamp(),
          'likesUp': 0,
          'likesDown': 0,
          'levelSum': 0,
          'levelCount': 0,
          'timesSum': 0,
          'timesCount': 0,
          'seeded': true,
        });
        toCreate++;
      }
      if (toCreate > 0) {
        await batch.commit();
      }
    } catch (_) {
      // no-op; seeding is best-effort
    }
  }

  Future<void> _enableCollab() async {
    final id = _selectedPackId;
    if (id == null) return;
    setState(() => _enabling = true);
    try {
      await _fs.enablePackContributions(id);
      final code = await _fs.getOrCreatePackContribCode(id);
      if (!mounted) return;
      setState(() => _shareCode = code);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Közös ötletelés engedélyezve.')),
      );
    } finally {
      if (mounted) setState(() => _enabling = false);
    }
  }

  Future<void> _submitProposal() async {
    final id = _selectedPackId;
    final name = _proposalController.text.trim();
    if (id == null || name.isEmpty) return;
    // Duplicate / fuzzy check against existing proposals and items
    final dup = await _findPotentialDuplicate(id, name);
    if (dup != null) {
      final proceed = await _confirmDuplicate(context, name, dup);
      if (!proceed) return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    try {
      await _fs.submitProposal(packId: id, name: name, createdBy: uid);
      _proposalController.clear();
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hiba: $e')));
    }
  }

  Future<String?> _findPotentialDuplicate(String packId, String name) async {
    final normalized = normalizeText(name);
    // Compare with existing pack items
    final pack = _packs.firstWhere((p) => p.id == packId);
    for (final it in pack.items) {
      final n = normalizeText(it.name);
      if (isCloseText(normalized, n)) return it.name;
    }
    // Compare with recent proposals (limit 50)
    final ps = await FirebaseFirestore.instance
        .collection('packs')
        .doc(packId)
        .collection('proposals')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    for (final d in ps.docs) {
      final other = (d.data()['name'] ?? '').toString();
      if (isCloseText(normalized, normalizeText(other))) return other;
    }
    return null;
  }

  Future<bool> _confirmDuplicate(
      BuildContext context, String candidate, String existing) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Lehetséges duplikátum'),
            content: Text(
                '"$candidate" hasonló lehet ehhez: "$existing". Hozzáadod így is?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Mégse')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Hozzáadás')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _importConsensusIntoPack() async {
    final id = _selectedPackId;
    if (id == null) return;
    try {
      final items = await _fs.buildConsensusItems(id);
      if (items.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nincs elegendő javaslat/szavazat.')));
        return;
      }
      final pack = _packs.firstWhere((p) => p.id == id);
      final updated = pack.copyWith(items: items);
      await _fs.savePack(id, updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Csomag frissítve a szavazatok alapján.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Import hiba: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeKey = _autoThemeKey();
    return Scaffold(
      appBar: GradientBlurAppBar(
        themeKey: themeKey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Közös csomag ötletelés'),
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
          SeasonalGradientBackground(themeKey: themeKey),
          if (themeKey == 'christmas') ...[
            const IgnorePointer(child: SnowfallOverlay()),
            const IgnorePointer(child: TwinklesOverlay()),
          ] else ...[
            const IgnorePointer(child: HoppingBunniesOverlay()),
            const IgnorePointer(child: PastelFloatersOverlay()),
          ],
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox.expand(
                    child: GlassyPanel(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildPackDropdown(context)),
                              const SizedBox(width: 8),
                              AppPrimaryButton(
                                onPressed: _selectedPackId == null || _enabling
                                    ? null
                                    : _enableCollab,
                                icon: _enabling
                                    ? Icons.hourglass_empty
                                    : Icons.group_add_outlined,
                                child: const Text('Ötletelés engedélyezése'),
                              ),
                            ],
                          ),
                          if (_shareCode != null) ...[
                            const SizedBox(height: 8),
                            _buildShareCodeRow(context, _shareCode!),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                AppOutlinedButton(
                                  onPressed: _selectedPackId == null
                                      ? null
                                      : () async {
                                          final link = _buildCollabLink(
                                              _selectedPackId!);
                                          await ShareUtils.shareOrCopy(
                                            context,
                                            link,
                                            subject: 'Csomag szerkesztői link',
                                            copyMessage:
                                                'Szerkesztői link másolva.',
                                          );
                                        },
                                  icon: Icons.share_outlined,
                                  child:
                                      const Text('Szerkesztői link másolása'),
                                ),
                                const SizedBox(width: 8),
                                AppOutlinedButton(
                                  onPressed: _shareCode == null
                                      ? null
                                      : () async {
                                          final link =
                                              _buildContribLink(_shareCode!);
                                          await ShareUtils.shareOrCopy(
                                            context,
                                            link,
                                            subject: 'Közreműködői link',
                                            copyMessage:
                                                'Közreműködői link másolva.',
                                          );
                                        },
                                  icon: Icons.public_outlined,
                                  child:
                                      const Text('Közreműködői link másolása'),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _proposalController,
                                  decoration: InputDecoration(
                                    labelText: 'Új javaslat (tétel neve)',
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.06),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              AppPrimaryButton(
                                onPressed: _selectedPackId == null
                                    ? null
                                    : _submitProposal,
                                icon: Icons.add,
                                child: const Text('Hozzáadás'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.06)),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: _buildProposalsList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SafeArea(
                            top: false,
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _selectedPackId == null
                                        ? null
                                        : _importConsensusIntoPack,
                                    icon: const Icon(Icons.download_outlined),
                                    label: const Text(
                                        'Importálás szavazatokból a csomagba'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPackDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selectedPackId,
      decoration: InputDecoration(
        labelText: 'Csomag kiválasztása',
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
      onChanged: _onPackChanged,
      items: _packs
          .map((p) => DropdownMenuItem<String>(
                value: p.id,
                child: Text(p.name),
              ))
          .toList(),
    );
  }

  Widget _buildShareCodeRow(BuildContext context, String code) {
    return InkWell(
      onTap: () async {
        await ShareUtils.copyToClipboard(
          context,
          code,
          message: 'Kód vágólapra másolva: $code',
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            const Icon(Icons.key, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Megosztási kód: $code',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.copy, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProposalsList() {
    final id = _selectedPackId;
    if (id == null) {
      return const Center(child: Text('Válassz egy csomagot a kezdéshez.'));
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('packs')
          .doc(id)
          .collection('proposals')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
              child: Text('Még nincs javaslat. Adj hozzá az elsőt!'));
        }
        return ListView.builder(
          controller: _scroll,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index];
            final data = d.data();
            final name = data['name']?.toString() ?? '';
            final likesUp = (data['likesUp'] ?? 0) as int;
            final likesDown = (data['likesDown'] ?? 0) as int;
            final levelSum = (data['levelSum'] ?? 0) as int;
            final levelCount = (data['levelCount'] ?? 0) as int;
            final timesSum = (data['timesSum'] ?? 0) as int;
            final timesCount = (data['timesCount'] ?? 0) as int;
            final avgLevel = levelCount == 0 ? 3 : (levelSum / levelCount);
            final avgTimes = timesCount == 0 ? 1 : (timesSum / timesCount);

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                          '👍 $likesUp   👎 $likesDown   •   Szint átlag: ${avgLevel.toStringAsFixed(1)}   •   Ismétlés átlag: ${avgTimes.toStringAsFixed(1)}x'),
                    ),
                    VoteRow(
                      packId: id,
                      proposalId: d.id,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

String _autoThemeKey() {
  final month = DateTime.now().month;
  return (month == 10 || month == 11 || month == 12 || month == 1)
      ? 'christmas'
      : 'easter';
}

// Text helpers now provided by core/utils/text_utils.dart: normalizeText, isCloseText, levDistance

String _buildCollabLink(String packId) {
  final base = Uri.base;
  final path = '${base.origin}${base.path}#/collab?packId=$packId';
  return path;
}

String _buildContribLink(String code) {
  final base = Uri.base;
  final path = '${base.origin}${base.path}#/contribute?code=$code';
  return path;
}
