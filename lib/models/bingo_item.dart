class BingoItem {
  final String name;
  final int level; // difficulty 1..5
  final int times; // how many times this item can occur in the pool

  BingoItem({required this.name, required this.level, this.times = 1});

  BingoItem copyWith({String? name, int? level, int? times}) {
    return BingoItem(
      name: name ?? this.name,
      level: level ?? this.level,
      times: times ?? this.times,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
      'times': times,
    };
  }

  factory BingoItem.fromMap(Map<String, dynamic> map) {
    return BingoItem(
      name: map['name'] as String,
      level: map['level'] as int,
      times: (map['times'] as int?) ?? 1,
    );
  }
}
