import 'package:cloud_firestore/cloud_firestore.dart';

import 'bingo_item.dart';

class Pack {
  final String id;
  final String name;
  final List<BingoItem> items;

  Pack({
    required this.id,
    required this.name,
    required this.items,
  });

  Pack copyWith({
    String? id,
    String? name,
    List<BingoItem>? items,
  }) {
    return Pack(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }

  factory Pack.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pack(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Pack',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => BingoItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}
