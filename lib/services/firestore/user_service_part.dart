part of 'firestore_service.dart';

extension UserService on FirestoreService {
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<void> ensureUserProfile({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    final doc = _users.doc(uid);
    final snap = await doc.get();
    final now = FieldValue.serverTimestamp();
    if (snap.exists) {
      await doc.update({
        'lastSignInAt': now,
      });
      return;
    }
    final name = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : (email.split('@').first);
    await doc.set({
      'email': email,
      'displayName': name,
      'createdAt': now,
      'lastSignInAt': now,
      'stats': {
        'gamesOwned': 0,
        'gamesPlayed': 0,
        'gamesWon': 0,
        'tilesMarked': 0,
      },
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(String uid) {
    return _users.doc(uid).snapshots();
  }

  Future<void> incrementUserStat(String uid, String statKey, int by) async {
    await _users.doc(uid).update({'stats.$statKey': FieldValue.increment(by)});
  }
}
