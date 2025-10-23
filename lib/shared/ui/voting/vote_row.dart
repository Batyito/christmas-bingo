import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/firestore/firestore_service.dart';

/// Reusable voting row with like/dislike, level and times selectors.
///
/// Use this for proposals in both collab and contribute screens to avoid
/// duplication and keep behavior consistent.
class VoteRow extends StatefulWidget {
  final String packId;
  final String proposalId;
  const VoteRow({super.key, required this.packId, required this.proposalId});

  @override
  State<VoteRow> createState() => _VoteRowState();
}

class _VoteRowState extends State<VoteRow> {
  bool? _like; // null/true/false
  int? _level; // 1..5
  int? _times; // 1..5
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadMyVote();
  }

  Future<void> _loadMyVote() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance
        .collection('packs')
        .doc(widget.packId)
        .collection('proposals')
        .doc(widget.proposalId)
        .collection('votes')
        .doc(uid);
    final snap = await ref.get();
    if (!mounted) return;
    if (snap.exists) {
      final data = snap.data()!;
      setState(() {
        _like = data['like'] as bool?;
        _level = (data['level'] as int?);
        _times = (data['times'] as int?);
      });
    }
  }

  Future<void> _vote({bool? like, int? level, int? times}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await FirestoreService.instance.voteOnProposal(
        packId: widget.packId,
        proposalId: widget.proposalId,
        uid: FirebaseAuth.instance.currentUser?.uid ?? 'guest',
        like: like,
        level: level,
        times: times,
      );
      if (!mounted) return;
      setState(() {
        _like = like ?? _like;
        _level = level ?? _level;
        _times = times ?? _times;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          // Like / Dislike toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, icon: Icon(Icons.thumb_up_outlined)),
              ButtonSegment(
                  value: false, icon: Icon(Icons.thumb_down_outlined)),
            ],
            selected: _like == null ? <bool>{} : {_like!},
            onSelectionChanged: (sel) {
              final next = sel.isEmpty ? null : sel.first;
              _vote(like: next);
            },
            multiSelectionEnabled: false,
            emptySelectionAllowed: true,
          ),
          const SizedBox(width: 12),
          // Level dropdown
          DropdownButton<int>(
            value: _level ?? 3,
            onChanged: (v) {
              if (v != null) _vote(level: v);
            },
            items: List.generate(
              5,
              (i) =>
                  DropdownMenuItem(value: i + 1, child: Text('Szint ${i + 1}')),
            ),
          ),
          const SizedBox(width: 12),
          // Times stepper
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Kevesebb',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    final current = _times ?? 1;
                    final next = (current - 1).clamp(1, 5);
                    if (next != current) _vote(times: next);
                  },
                ),
                Text('${(_times ?? 1)}x'),
                IconButton(
                  tooltip: 'Több',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    final current = _times ?? 1;
                    final next = (current + 1).clamp(1, 5);
                    if (next != current) _vote(times: next);
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }
}
