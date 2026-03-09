import 'package:game_setter/features/players/domain/entities/player_sport.dart';

class Player {
  final int? id;
  final String name;
  final String? phone;
  final int? position;
  final List<PlayerSport>? sports;
  String? subtitle;

  Player({this.id, required this.name, this.phone, this.sports, this.position, this.subtitle});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'phone': phone, 'position': position};
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      phone: map['phone'] as String?,
      position: map['position'] as int?,
      sports: (map['sports'] as List?)?.map((e) => PlayerSport.fromMap(e as Map<String, dynamic>)).toList(),
    );
  }

  Player copyWith({String? name, String? phone, List<PlayerSport>? sports, int? position, String? subtitle}) {
    return Player(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      sports: sports ?? this.sports,
      position: position ?? this.position,
      subtitle: subtitle ?? this.subtitle,
    );
  }
}
