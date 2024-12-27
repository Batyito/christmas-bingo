part of 'firestore_service.dart';

extension SettingsService on FirestoreService {
  Future<List<String>> _fetchOrInitializeBingoItems() async {
    final docRef = _db.collection('settings').doc('bingoItems');
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      return List<String>.from(docSnapshot.data()!['items']);
    } else {
      final defaultItems = [
        "Katák🫠",
        "Ági 🍕",
        "Szelfi 🤳",
        "Kaja fotó 📸🥙",
        "Mexikó 🇲🇽",
        "Dávid orvosi kérdések 👨‍⚕️😷",
        "Boldi és Zoé 🤨",
        "Dobos Mikulás 🎅",
        "\"Nem kellett volna\" 🤭",
        "Mama törött kezei ✋",
        "\"Jaj maradj már\" 😠",
        "Zoli eszi meg Zoé maradékát🍞",
        "Zoli lever valamit 💔",
        "Mami átöltözik 👗",
        "Petya síelés ⛷️",
        "Legfiatalabb bontja a pezsgőt 🍾",
        "Húzzuk arrébb az asztalt 🪑",
        "Ne vedd le a cipőt 👟",
        "\"Ti nem isztok?\" 🥃",
        "\"Papi hozd be kintről\"",
        "Timi kérdez mit, aztán nem figyel🥲",
        "Mami \"Mit kérsz?\" 🍗🍟🧆",
        "Zoli nyugdíj👴",
        "Boldi káromkodik 😱",
        "Rebi Sára lesz 🦄",
        "Zoli és Sára pillanat ❤️‍🔥",
        "\"Levike most nincs rántott hús\" 😢",
        "Rebi szemüveg 🤓",
        "\"Na\" 🫢",
        "Vanda új munka 💼",
        "Dorka munka/tanulás📚",
        "Timi egyetem 🎓",
        "Mikor fotózkodunk? 📷",
        "Mami kezébe ordító gyerek😭",
        "Koccintás fájl 🥂",
        "Zoli tölt 🫗",
        "\"Dávid ízlik?\" 🙄",
        "Egyél/egyetek még 🥗",
        "Utalás a gyerekre 👶🍼",
        "Minaret 🕌"
      ];

      await docRef.set({'items': defaultItems});
      return defaultItems;
    }
  }

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
