import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/utils/share_utils.dart';

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
import '../shared/ui/inputs/app_text_field.dart';

class ContributeByCodeScreen extends StatefulWidget {
  final String? initialCode;
  const ContributeByCodeScreen({super.key, this.initialCode});

  @override
  State<ContributeByCodeScreen> createState() => _ContributeByCodeScreenState();
}

class _ContributeByCodeScreenState extends State<ContributeByCodeScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _proposalCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  String? _packId;
  String? _packName;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _codeCtrl.text = widget.initialCode!;
      _lookupPack();
    }
  }

  Future<void> _lookupPack() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    try {
      final qs = await FirebaseFirestore.instance
          .collection('packs')
          .where('contribCode', isEqualTo: code)
          .limit(1)
          .get();
      if (qs.docs.isEmpty) {
        if (!mounted) return;
        setState(() {
          _packId = null;
          _packName = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nincs csomag ezzel a kóddal.')),
        );
      } else {
        final d = qs.docs.first;
        if (!mounted) return;
        setState(() {
          _packId = d.id;
          _packName = (d.data()['name'] ?? '').toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitProposal() async {
    final id = _packId;
    final name = _proposalCtrl.text.trim();
    if (id == null || name.isEmpty) return;

    // Duplicate / fuzzy check against recent proposals only (no pack items available here)
    final dup = await _findPotentialDuplicate(id, name);
    if (dup != null) {
      final proceed = await _confirmDuplicate(context, name, dup);
      if (!proceed) return;
    }

    try {
      final ref = FirebaseFirestore.instance
          .collection('packs')
          .doc(id)
          .collection('proposals')
          .doc();
      await ref.set({
        'name': name,
        'createdBy': FirebaseAuth.instance.currentUser?.uid ?? 'guest',
        'createdAt': FieldValue.serverTimestamp(),
        'likesUp': 0,
        'likesDown': 0,
        'levelSum': 0,
        'levelCount': 0,
        'timesSum': 0,
        'timesCount': 0,
      });
      _proposalCtrl.clear();
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hiba: $e')));
    }
  }

  Future<String?> _findPotentialDuplicate(String packId, String name) async {
    final normalized = normalizeText(name);
    final ps = await FirebaseFirestore.instance
        .collection('packs')
        .doc(packId)
        .collection('proposals')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    for (final d in ps.docs) {
      final other = (d.data()['name'] ?? '').toString();
      if (isCloseText(normalizeText(other), normalized)) return other;
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

  Future<void> _showVotersDialog(String packId, String proposalId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('packs')
          .doc(packId)
          .collection('proposals')
          .doc(proposalId)
          .collection('votes')
          .orderBy('updatedAt', descending: true)
          .get();
      final votes = snap.docs.map((d) => d.data()).toList();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Szavazók'),
          content: SizedBox(
            width: 400,
            child: votes.isEmpty
                ? const Text('Még nincs szavazat.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final v in votes)
                        ListTile(
                          leading: Icon(
                            (v['like'] == true)
                                ? Icons.thumb_up_outlined
                                : (v['like'] == false)
                                    ? Icons.thumb_down_outlined
                                    : Icons.how_to_vote_outlined,
                          ),
                          title: Text(
                              'UID: ${_shortUid((v['uid'] ?? '—').toString())}'),
                          subtitle: Text(
                              'Szint: ${v['level'] ?? '—'}   •   Ismétlés: ${v['times'] ?? '—'}x'),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bezárás'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hiba a szavazók lekérdezésekor: $e')));
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
        title: const Text('Közreműködés kóddal'),
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
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
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
                            Expanded(
                              child: AppTextField(
                                controller: _codeCtrl,
                                label: 'Megosztási kód',
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _loading ? null : _lookupPack,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.search),
                              label: const Text('Keresés'),
                            ),
                          ],
                        ),
                        if (_packId != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.inventory_2_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _packName ?? _packId!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Link másolása',
                                  icon: const Icon(Icons.link),
                                  onPressed: () async {
                                    final link = _buildContribLink(
                                        _codeCtrl.text.trim());
                                    await ShareUtils.shareOrCopy(
                                      context,
                                      link,
                                      subject: 'Közreműködés link',
                                      copyMessage: 'Link vágólapra másolva.',
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _proposalCtrl,
                                  label: 'Új javaslat (tétel neve)',
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _submitProposal,
                                icon: const Icon(Icons.add),
                                label: const Text('Hozzáadás'),
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
                              child: _packId == null
                                  ? const SizedBox.shrink()
                                  : StreamBuilder<
                                      QuerySnapshot<Map<String, dynamic>>>(
                                      stream: FirebaseFirestore.instance
                                          .collection('packs')
                                          .doc(_packId)
                                          .collection('proposals')
                                          .orderBy('createdAt',
                                              descending: true)
                                          .snapshots(),
                                      builder: (context, snap) {
                                        if (snap.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        }
                                        final docs = snap.data?.docs ?? [];
                                        if (docs.isEmpty) {
                                          return const Center(
                                              child:
                                                  Text('Még nincs javaslat.'));
                                        }
                                        return ListView.builder(
                                          controller: _scroll,
                                          itemCount: docs.length,
                                          itemBuilder: (context, index) {
                                            final d = docs[index];
                                            final data = d.data();
                                            final name =
                                                data['name']?.toString() ?? '';
                                            final likesUp =
                                                (data['likesUp'] ?? 0) as int;
                                            final likesDown =
                                                (data['likesDown'] ?? 0) as int;
                                            final levelSum =
                                                (data['levelSum'] ?? 0) as int;
                                            final levelCount =
                                                (data['levelCount'] ?? 0)
                                                    as int;
                                            final timesSum =
                                                (data['timesSum'] ?? 0) as int;
                                            final timesCount =
                                                (data['timesCount'] ?? 0)
                                                    as int;
                                            final avgLevel = levelCount == 0
                                                ? 3
                                                : (levelSum / levelCount);
                                            final avgTimes = timesCount == 0
                                                ? 1
                                                : (timesSum / timesCount);
                                            final createdBy =
                                                (data['createdBy'] ?? '—')
                                                    .toString();

                                            return Card(
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  ListTile(
                                                    title: Text(name,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    subtitle: Text(
                                                        '👍 $likesUp   👎 $likesDown   •   Szint átlag: ${avgLevel.toStringAsFixed(1)}   •   Ismétlés átlag: ${avgTimes.toStringAsFixed(1)}x\nHozzáadta: ${_shortUid(createdBy)}'),
                                                    trailing: TextButton.icon(
                                                      icon: const Icon(
                                                          Icons.people_outline),
                                                      label: const Text(
                                                          'Szavazók'),
                                                      onPressed: () =>
                                                          _showVotersDialog(
                                                              _packId!, d.id),
                                                    ),
                                                  ),
                                                  VoteRow(
                                                      packId: _packId!,
                                                      proposalId: d.id),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

String _shortUid(String uid) =>
    uid.length <= 8 ? uid : '${uid.substring(0, 8)}…';

String _autoThemeKey() {
  final month = DateTime.now().month;
  return (month == 10 || month == 11 || month == 12 || month == 1)
      ? 'christmas'
      : 'easter';
}

String _buildContribLink(String code) {
  final base = Uri.base;
  return '${base.origin}${base.path}#/contribute?code=$code';
}
