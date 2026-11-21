import 'package:game_setter/features/players/domain/entities/player_sport.dart';

class Player {
  final int? id;
  final String name;
  final String? phone;
  final int? position;
  final List<PlayerSport>? sports;
  String? subtitle;

  /// Invitado: jugador de un solo partido. No aparece en la lista de Jugadores
  /// y puede ocupar cualquier posición en la formación de equipos.
  final bool isGuest;

  Player({this.id, required this.name, this.phone, this.sports, this.position, this.subtitle, this.isGuest = false});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'phone': phone, 'position': position, 'is_guest': isGuest ? 1 : 0};
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      phone: map['phone'] as String?,
      position: map['position'] as int?,
      sports: (map['sports'] as List?)?.map((e) => PlayerSport.fromMap(e as Map<String, dynamic>)).toList(),
      isGuest: (map['is_guest'] ?? 0) == 1,
    );
  }

  Player copyWith({String? name, String? phone, List<PlayerSport>? sports, int? position, String? subtitle, bool? isGuest}) {
    return Player(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      sports: sports ?? this.sports,
      position: position ?? this.position,
      subtitle: subtitle ?? this.subtitle,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}
