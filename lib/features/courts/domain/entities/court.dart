class Court {
  final int? id;
  final String name;
  final String? phone;
  final String? location;
  final double? hourlyRate;
  final int? position;
  String? subtitle;

  Court({this.id, required this.name, this.phone, this.location, this.hourlyRate, this.position, this.subtitle});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'phone': phone, 'location': location, 'hourly_rate': hourlyRate, 'position': position};
  }

  factory Court.fromMap(Map<String, dynamic> map) {
    return Court(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      location: map['location'],
      hourlyRate: map['hourly_rate'] != null ? (map['hourly_rate'] as num).toDouble() : null,
      position: map['position'],
    );
  }

  Court copyWith({String? name, String? phone, String? location, double? hourlyRate, int? position, String? subtitle}) {
    return Court(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      position: position ?? this.position,
      subtitle: subtitle ?? this.subtitle,
    );
  }
}
