import 'package:flutter/material.dart';

class SelectSportPage extends StatelessWidget {
  const SelectSportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Deporte')),
      body: const Center(child: Text('Aquí irá la lista de deportes desde SQLite')),
    );
  }
}
