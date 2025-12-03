class Court {
  final int? id;
  final String name;
  final String? phone;
  final String? location;
  final double? hourlyRate;

  Court({this.id, required this.name, this.phone, this.location, this.hourlyRate});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'phone': phone, 'location': location, 'hourly_rate': hourlyRate};
  }

  factory Court.fromMap(Map<String, dynamic> map) {
    return Court(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      location: map['location'],
      hourlyRate: map['hourly_rate'] != null ? (map['hourly_rate'] as num).toDouble() : null,
    );
  }
}
