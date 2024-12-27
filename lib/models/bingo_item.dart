class BingoItem {
  final String name;
  final int level;

  BingoItem({required this.name, required this.level});

  BingoItem copyWith({String? name, int? level}) {
    return BingoItem(
      name: name ?? this.name,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
    };
  }

  factory BingoItem.fromMap(Map<String, dynamic> map) {
    return BingoItem(
      name: map['name'] as String,
      level: map['level'] as int,
    );
  }
}
