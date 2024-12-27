import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class InitService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initializeDefaultData() async {
    await _createDefaultPacks();
  }

  Future<void> _createDefaultPacks() async {
    final defaultPackId = "default_2024_christmas";
    final defaultPackName = "2024 Christmas Pack";
    final List<Map<String, dynamic>> defaultItems = [
      {"name": "Katák🫠", "level": 1},
      {"name": "Ági 🍕", "level": 1},
      {"name": "Szelfi 🤳", "level": 2},
      {"name": "Kaja fotó 📸🥙", "level": 2},
      {"name": "Mexikó 🇲🇽", "level": 3},
      {"name": "Dávid orvosi kérdések 👨‍⚕️😷", "level": 2},
      {"name": "Boldi és Zoé 🤨", "level": 2},
      {"name": "Dobos Mikulás 🎅", "level": 3},
      {"name": "\"Nem kellett volna\" 🤭", "level": 1},
      {"name": "Mama törött kezei ✋", "level": 4},
      {"name": "\"Jaj maradj már\" 😠", "level": 3},
      {"name": "Zoli eszi meg Zoé maradékát🍞", "level": 1},
      {"name": "Zoli lever valamit 💔", "level": 2},
      {"name": "Mami átöltözik 👗", "level": 2},
      {"name": "Petya síelés ⛷️", "level": 5},
      {"name": "Legfiatalabb bontja a pezsgőt 🍾", "level": 4},
      {"name": "Húzzuk arrébb az asztalt 🪑", "level": 3},
      {"name": "Ne vedd le a cipőt 👟", "level": 2},
      {"name": "\"Ti nem isztok?\" 🥃", "level": 1},
      {"name": "\"Papi hozd be kintről\"", "level": 2},
      {"name": "Timi kérdez mit, aztán nem figyel🥲", "level": 3},
      {"name": "Mami \"Mit kérsz?\" 🍗🍟🧆", "level": 1},
      {"name": "Zoli nyugdíj👴", "level": 4},
      {"name": "Boldi káromkodik 😱", "level": 5},
      {"name": "Rebi Sára lesz 🦄", "level": 2},
      {"name": "Zoli és Sára pillanat ❤️‍🔥", "level": 1},
      {"name": "\"Levike most nincs rántott hús\" 😢", "level": 3},
      {"name": "Rebi szemüveg 🤓", "level": 1},
      {"name": "\"Na\" 🫢", "level": 2},
      {"name": "Vanda új munka 💼", "level": 4},
      {"name": "Dorka munka/tanulás📚", "level": 3},
      {"name": "Timi egyetem 🎓", "level": 2},
      {"name": "Mikor fotózkodunk? 📷", "level": 3},
      {"name": "Mami kezébe ordító gyerek😭", "level": 5},
      {"name": "Koccintás fájl 🥂", "level": 2},
      {"name": "Zoli tölt 🫗", "level": 1},
      {"name": "\"Dávid ízlik?\" 🙄", "level": 2},
      {"name": "Egyél/egyetek még 🥗", "level": 1},
      {"name": "Utalás a gyerekre 👶🍼", "level": 2},
      {"name": "Minaret 🕌", "level": 5},

    ];

    // Check if the pack already exists
    final packDoc = await _db.collection('packs').doc(defaultPackId).get();
    if (!packDoc.exists) {
      await _db.collection('packs').doc(defaultPackId).set({
        "id": defaultPackId,
        "name": defaultPackName,
        "items": defaultItems,
        "createdAt": FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print("Default pack created");
      }
    } else {
      if (kDebugMode) {
        print("Default pack already exists");
      }
    }
  }
}
