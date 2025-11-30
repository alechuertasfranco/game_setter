class Position {
  final int id;
  final int sportId;
  final String name;
  final String shortName;

  Position({required this.id, required this.sportId, required this.name, required this.shortName});

  factory Position.fromMap(Map<String, dynamic> map) {
    return Position(id: map['id'] as int, sportId: map['sport_id'] as int, name: map['name'] as String, shortName: map['short_name'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'sport_id': sportId, 'name': name, 'short_name': shortName};
  }
}
