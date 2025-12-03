import 'package:flutter/material.dart';

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

  /// Devuelve un icono según el deporte
  static Icon getIcon(String? sportName) {
    switch (sportName?.toLowerCase()) {
      case 'fútbol':
        return const Icon(Icons.sports_soccer, color: Colors.blue, size: 28);
      case 'baloncesto':
      case 'básquet':
        return const Icon(Icons.sports_basketball, color: Colors.blue, size: 28);
      case 'voley':
      case 'vóley':
        return const Icon(Icons.sports_volleyball, color: Colors.blue, size: 28);
      default:
        return const Icon(Icons.sports, color: Colors.blue, size: 28);
    }
  }
}
