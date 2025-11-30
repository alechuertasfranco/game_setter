class Player {
  final String id;
  final String name;
  final String? phone;

  Player({required this.id, required this.name, this.phone});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'phone': phone};
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(id: map['id'], name: map['name'], phone: map['phone']);
  }
}
