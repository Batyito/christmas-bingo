part of 'firestore_service.dart';

extension PackService on FirestoreService {
  Future<List<Pack>> fetchPacks() async {
    final snapshot = await _db.collection('packs').get();
    return snapshot.docs.map((doc) => Pack.fromFirestore(doc)).toList();
  }

  Future<void> savePack(String packId, Pack pack) async {
    await _db.collection('packs').doc(packId).set(pack.toMap());
  }

  Future<void> saveDefaultPack() async {
    final defaultPack = Pack(
      id: "default_2024_christmas",
      name: "2024 Karácsonyi Pack",
      items: [
        BingoItem(name: "Katák🫠", level: 1),
        BingoItem(name: "Ági 🍕", level: 1),
        BingoItem(name: "Szelfi 🤳", level: 2),
        BingoItem(name: "Kaja fotó 📸🥙", level: 2),
        BingoItem(name: "Mexikó 🇲🇽", level: 3),
        BingoItem(name: "Dávid orvosi kérdések 👨‍⚕️😷", level: 2),
        BingoItem(name: "Boldi és Zoé 🤨", level: 2),
        BingoItem(name: "Dobos Mikulás 🎅", level: 3),
        BingoItem(name: "\"Nem kellett volna\" 🤭", level: 1),
        BingoItem(name: "Mama törött kezei ✋", level: 4),
        BingoItem(name: "\"Jaj maradj már\" 😠", level: 3),
        BingoItem(name: "Zoli eszi meg Zoé maradékát🍞", level: 1),
        BingoItem(name: "Zoli lever valamit 💔", level: 2),
        BingoItem(name: "Mami átöltözik 👗", level: 2),
        BingoItem(name: "Petya síelés ⛷️", level: 5),
        BingoItem(name: "Legfiatalabb bontja a pezsgőt 🍾", level: 4),
        BingoItem(name: "Húzzuk arrébb az asztalt 🪑", level: 3),
        BingoItem(name: "Ne vedd le a cipőt 👟", level: 2),
        BingoItem(name: "\"Ti nem isztok?\" 🥃", level: 1),
        BingoItem(name: "\"Papi hozd be kintről\"", level: 2),
        BingoItem(name: "Timi kérdez mit, aztán nem figyel🥲", level: 3),
        BingoItem(name: "Mami \"Mit kérsz?\" 🍗🍟🧆", level: 1),
        BingoItem(name: "Zoli nyugdíj👴", level: 4),
        BingoItem(name: "Boldi káromkodik 😱", level: 5),
        BingoItem(name: "Rebi Sára lesz 🦄", level: 2),
        BingoItem(name: "Zoli és Sára pillanat ❤️‍🔥", level: 1),
        BingoItem(name: "\"Levike most nincs rántott hús\" 😢", level: 3),
        BingoItem(name: "Rebi szemüveg 🤓", level: 1),
        BingoItem(name: "\"Na\" 🫢", level: 2),
        BingoItem(name: "Vanda új munka 💼", level: 4),
        BingoItem(name: "Dorka munka/tanulás📚", level: 3),
        BingoItem(name: "Timi egyetem 🎓", level: 2),
        BingoItem(name: "Mikor fotózkodunk? 📷", level: 3),
        BingoItem(name: "Mami kezébe ordító gyerek😭", level: 5),
        BingoItem(name: "Koccintás fájl 🥂", level: 2),
        BingoItem(name: "Zoli tölt 🫗", level: 1),
        BingoItem(name: "\"Dávid ízlik?\" 🙄", level: 2),
        BingoItem(name: "Egyél/egyetek még 🥗", level: 1),
        BingoItem(name: "Utalás a gyerekre 👶🍼", level: 2),
        BingoItem(name: "Minaret 🕌", level: 5),
      ],
    );

    await savePack(defaultPack.id, defaultPack);
  }

  // --- Collaborative pack contributions & voting ---

  Future<void> enablePackContributions(String packId) async {
    await _db.collection('packs').doc(packId).set({
      'enableVoting': true,
      'contribCode': _generateShareCode(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> getOrCreatePackContribCode(String packId) async {
    final ref = _db.collection('packs').doc(packId);
    final snap = await ref.get();
    final code = snap.data()?['contribCode']?.toString();
    if (code != null && code.isNotEmpty) return code;
    final newCode = _generateShareCode();
    await ref.set({'contribCode': newCode}, SetOptions(merge: true));
    return newCode;
  }

  Future<DocumentReference<Map<String, dynamic>>> submitProposal({
    required String packId,
    required String name,
    required String createdBy,
  }) async {
    final proposals =
        _db.collection('packs').doc(packId).collection('proposals');
    final ref = proposals.doc();
    await ref.set({
      'name': name.trim(),
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      // aggregates
      'likesUp': 0,
      'likesDown': 0,
      'levelSum': 0,
      'levelCount': 0,
      'timesSum': 0,
      'timesCount': 0,
    });
    return ref;
  }

  /// Record or update a user's vote for a proposal. Supports partial updates
  /// (like only voting like/dislike or only level/times). Ensures aggregates
  /// are adjusted by delta when users change their vote.
  Future<void> voteOnProposal({
    required String packId,
    required String proposalId,
    required String uid,
    bool? like, // true=up, false=down, null=no like vote
    int? level, // 1..5
    int? times, // 1..5 occurrences weight
  }) async {
    final propRef = _db
        .collection('packs')
        .doc(packId)
        .collection('proposals')
        .doc(proposalId);
    final voteRef = propRef.collection('votes').doc(uid);

    await _db.runTransaction((tx) async {
      final propSnap = await tx.get(propRef);
      if (!propSnap.exists) throw Exception('Proposal not found');
      final voteSnap = await tx.get(voteRef);
      final prev = voteSnap.data();

      int likesUpDelta = 0;
      int likesDownDelta = 0;
      int levelSumDelta = 0;
      int levelCountDelta = 0;
      int timesSumDelta = 0;
      int timesCountDelta = 0;

      // Like/dislike delta
      if (like != null) {
        final prevLike = prev?['like'];
        if (prevLike == null) {
          likesUpDelta += like ? 1 : 0;
          likesDownDelta += like ? 0 : 1;
        } else if (prevLike != like) {
          // switch
          likesUpDelta += like ? 1 : -1;
          likesDownDelta += like ? -1 : 1;
        }
      }

      // Level delta
      if (level != null) {
        final prevLevel = prev?['level'] as int?;
        if (prevLevel == null) {
          levelSumDelta += level;
          levelCountDelta += 1;
        } else if (prevLevel != level) {
          levelSumDelta += (level - prevLevel);
        }
      }

      // Times delta
      if (times != null) {
        final prevTimes = prev?['times'] as int?;
        if (prevTimes == null) {
          timesSumDelta += times;
          timesCountDelta += 1;
        } else if (prevTimes != times) {
          timesSumDelta += (times - prevTimes);
        }
      }

      // Apply aggregate deltas
      final updates = <String, dynamic>{};
      if (likesUpDelta != 0)
        updates['likesUp'] = FieldValue.increment(likesUpDelta);
      if (likesDownDelta != 0) {
        updates['likesDown'] = FieldValue.increment(likesDownDelta);
      }
      if (levelSumDelta != 0)
        updates['levelSum'] = FieldValue.increment(levelSumDelta);
      if (levelCountDelta != 0) {
        updates['levelCount'] = FieldValue.increment(levelCountDelta);
      }
      if (timesSumDelta != 0)
        updates['timesSum'] = FieldValue.increment(timesSumDelta);
      if (timesCountDelta != 0) {
        updates['timesCount'] = FieldValue.increment(timesCountDelta);
      }
      if (updates.isNotEmpty) tx.update(propRef, updates);

      // Upsert vote doc
      final next = {
        if (like != null) 'like': like,
        if (level != null) 'level': level,
        if (times != null) 'times': times,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (voteSnap.exists) {
        tx.update(voteRef, next);
      } else {
        tx.set(voteRef, {
          ...next,
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Build consensus items from proposals using averages and likes.
  /// - level: rounded average of level votes (default 3)
  /// - times: rounded average of times (default 1)
  /// - weight multiplier: max(1, likesUp - likesDown + 1)
  Future<List<BingoItem>> buildConsensusItems(String packId) async {
    final snap =
        await _db.collection('packs').doc(packId).collection('proposals').get();
    final List<BingoItem> out = [];
    for (final d in snap.docs) {
      final data = d.data();
      final name = data['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      final levelCount = (data['levelCount'] ?? 0) as int;
      final timesCount = (data['timesCount'] ?? 0) as int;
      final avgLevel =
          levelCount == 0 ? 3 : ((data['levelSum'] ?? 0) as int) / levelCount;
      final avgTimes =
          timesCount == 0 ? 1 : ((data['timesSum'] ?? 0) as int) / timesCount;
      final level = avgLevel.clamp(1, 5).round();
      final times = avgTimes.clamp(1, 5).round();
      final likesUp = (data['likesUp'] ?? 0) as int;
      final likesDown = (data['likesDown'] ?? 0) as int;
      final weight = (likesUp - likesDown + 1);
      final effectiveTimes = (times * weight).clamp(1, 10);
      out.add(BingoItem(name: name, level: level, times: effectiveTimes));
    }
    return out;
  }
}
