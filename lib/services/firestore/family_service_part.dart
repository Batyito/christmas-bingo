part of 'firestore_service.dart';

class Family {
  final String id;
  final String name;
  final String ownerId;
  final List<String> members;
  final List<String> packIds; // packs available to family

  Family(
      {required this.id,
      required this.name,
      required this.ownerId,
      required this.members,
      this.packIds = const []});

  Map<String, dynamic> toMap() => {
        'name': name,
        'ownerId': ownerId,
        'members': members,
        'packIds': packIds,
      };
}

extension FamilyService on FirestoreService {
  // --- Invites ---
  Future<String> createTeamInvite({
    required String familyId,
    required String teamId,
    Duration? ttl,
  }) async {
    final code = _generateInviteCode();
    final ref =
        _db.collection('families').doc(familyId).collection('invites').doc();
    final expiresAt =
        ttl == null ? null : Timestamp.fromDate(DateTime.now().add(ttl));
    await ref.set({
      'teamId': teamId,
      'code': code,
      'isPublic': true,
      'createdAt': FieldValue.serverTimestamp(),
      if (expiresAt != null) 'expiresAt': expiresAt,
      'status': 'pending',
    });
    return code;
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> resolveInviteByCode(
      String code) async {
    final snap = await _db
        .collectionGroup('invites')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  /// Accepts an invite by code and adds the user to the family, and if a team
  /// is associated attempts to add them as a participant (max 4). Returns a map
  /// with keys: familyId, teamId (optional), teamJoined (bool).
  Future<Map<String, dynamic>> acceptInviteWithCode(
      {required String code, required String uid}) async {
    final inviteDoc = await resolveInviteByCode(code);
    if (inviteDoc == null) {
      throw Exception('A meghívó nem található vagy lejárt.');
    }
    final familyId = inviteDoc.reference.parent.parent!.id;
    final teamId = inviteDoc.data()['teamId']?.toString();

    // Add to family members
    await _db.collection('families').doc(familyId).update({
      'members': FieldValue.arrayUnion([uid])
    });

    var teamJoined = false;
    if (teamId != null && teamId.isNotEmpty) {
      final teamRef = _db
          .collection('families')
          .doc(familyId)
          .collection('teams')
          .doc(teamId);
      await _db.runTransaction((trx) async {
        final snap = await trx.get(teamRef);
        if (!snap.exists) return;
        final parts = List<String>.from(snap.data()!['participants'] ?? []);
        if (!parts.contains(uid) && parts.length < 4) {
          parts.add(uid);
          trx.update(teamRef, {'participants': parts});
          teamJoined = true;
        }
      });
    }

    // Mark invite accepted (best-effort)
    try {
      await inviteDoc.reference.update({
        'status': 'accepted',
        'acceptedBy': uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return {
      'familyId': familyId,
      if (teamId != null) 'teamId': teamId,
      'teamJoined': teamJoined,
    };
  }

  String _generateInviteCode() {
    // Web-safe 32-bit PRNG to avoid JS int precision issues.
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    // Derive a 32-bit seed from current time via FNV-1a 32-bit.
    final seed = _fnv1a32(DateTime.now().microsecondsSinceEpoch.toString());
    int x = seed & 0xFFFFFFFF;
    final buf = StringBuffer();
    for (int i = 0; i < 10; i++) {
      // LCG parameters (Numerical Recipes), constrained to 32-bit.
      x = (x * 1664525 + 1013904223) & 0xFFFFFFFF;
      final idx = (x & 0x7fffffff) % alphabet.length;
      buf.write(alphabet[idx]);
    }
    return buf.toString();
  }

  Future<String> createFamily(
      {required String name, required String ownerId}) async {
    final doc = _db.collection('families').doc();
    final family = Family(
      id: doc.id,
      name: name,
      ownerId: ownerId,
      members: [ownerId],
      packIds: const [],
    );
    await doc.set(family.toMap());
    return doc.id;
  }

  Future<void> inviteToFamily(
      {required String familyId, required String email}) async {
    // Store a pending invite; later you can send an email or share a code.
    final code = _generateInviteCode();
    await _db.collection('families').doc(familyId).collection('invites').add({
      'email': email,
      'code': code,
      'isPublic': true,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Future<void> addMemberByUid(
      {required String familyId, required String uid}) async {
    await _db.collection('families').doc(familyId).update({
      'members': FieldValue.arrayUnion([uid])
    });
  }

  // STREAMS & HELPERS
  Stream<QuerySnapshot<Map<String, dynamic>>> streamFamiliesForUser(
      String uid) {
    return _db
        .collection('families')
        .where('members', arrayContains: uid)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getOwnedFamily(
      String uid) async {
    final snap = await _db
        .collection('families')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Future<void> setFamilyPacks(
      {required String familyId, required List<String> packIds}) async {
    await _db.collection('families').doc(familyId).update({'packIds': packIds});
  }

  // Family Teams subcollection CRUD
  Future<String> addFamilyTeam({
    required String familyId,
    required String name,
    required String colorHex, // ARGB hex string
    required List<String> participantUids, // max 4
  }) async {
    if (participantUids.length > 4) {
      throw Exception('A csapat maximum 4 játékost tartalmazhat.');
    }
    final ref =
        _db.collection('families').doc(familyId).collection('teams').doc();
    await ref.set({
      'name': name,
      'color': colorHex,
      'participants': participantUids,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateFamilyTeam({
    required String familyId,
    required String teamId,
    String? name,
    String? colorHex,
    List<String>? participantUids,
  }) async {
    if (participantUids != null && participantUids.length > 4) {
      throw Exception('A csapat maximum 4 játékost tartalmazhat.');
    }
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (colorHex != null) data['color'] = colorHex;
    if (participantUids != null) data['participants'] = participantUids;
    await _db
        .collection('families')
        .doc(familyId)
        .collection('teams')
        .doc(teamId)
        .update(data);
  }

  Future<void> deleteFamilyTeam({
    required String familyId,
    required String teamId,
  }) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('teams')
        .doc(teamId)
        .delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamFamilyTeams(
      String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('teams')
        .orderBy('name')
        .snapshots();
  }
}

// FNV-1a 32-bit hash for seeding, JS-safe (kept to 32-bit operations)
int _fnv1a32(String input) {
  int hash = 0x811C9DC5;
  for (final codeUnit in input.codeUnits) {
    hash ^= codeUnit & 0xFF;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0xFFFFFFFF;
}
