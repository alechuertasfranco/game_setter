import 'package:flutter/material.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';

class PlayerCard extends StatelessWidget {
  final Player player;

  const PlayerCard({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(title: Text(player.name), subtitle: Text(player.phone ?? "Sin teléfono"), leading: const Icon(Icons.person)),
    );
  }
}
