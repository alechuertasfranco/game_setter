import 'package:game_setter/features/players/domain/entities/player_sport.dart';

class Player {
  final String id;
  final String name;
  final String? phone;
  final List<PlayerSport>? sports;

  Player({required this.id, required this.name, this.phone, this.sports});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'phone': phone};
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(id: map['id'], name: map['name'], phone: map['phone'], sports: map['sports']);
  }

  Player copyWith({String? name, String? phone, List<PlayerSport>? sports}) {
    return Player(id: id, name: name ?? this.name, phone: phone ?? this.phone, sports: sports ?? this.sports);
  }
}
