class Sport {
  final int id;
  final String name;

  Sport({required this.id, required this.name});

  factory Sport.fromMap(Map<String, dynamic> map) {
    return Sport(id: map['id'] as int, name: map['name'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}
