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
}
