part of 'firestore_service.dart';

extension SettingsService on FirestoreService {
  // Removed unused _fetchOrInitializeBingoItems to reduce analyzer warnings.

  Future<void> saveBingoItems(List<String> items) async {
    await _db.collection('settings').doc('bingoItems').set({'items': items});
  }

  Future<List<String>> getBingoItems() async {
    final doc = await _db.collection('settings').doc('bingoItems').get();
    if (doc.exists && doc.data() != null) {
      return List<String>.from(doc.data()!['items']);
    }
    throw Exception("Bingo items not found.");
  }
}
