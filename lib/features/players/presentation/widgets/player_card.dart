import 'package:flutter/material.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/players/data/player_repository.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onAction;

  const PlayerCard({super.key, required this.player, this.onAction});

  Future<List<Map<String, dynamic>>> _loadSports() {
    return PlayerRepository().getPlayerSports(player.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadSports(),
      builder: (context, snapshot) {
        String subtitle = player.phone ?? "Sin teléfono";

        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          final sports = snapshot.data!;

          if (sports.isNotEmpty) {
            final uniqueSports = sports.map((sp) => sp['sport_name'] as String?).where((name) => name != null && name.trim().isNotEmpty).toSet().toList();
            if (uniqueSports.isNotEmpty) subtitle = uniqueSports.join(" - ");
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            title: Text(player.name),
            subtitle: Text(subtitle),
            leading: const Icon(Icons.person),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.grey),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Eliminar jugador"),
                    content: Text("¿Seguro que deseas eliminar a este jugador?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Eliminar")),
                    ],
                  ),
                );

                if (confirm == true) {
                  await PlayerRepository().clearPlayerSports(player.id);
                  await PlayerRepository().deletePlayer(player.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jugador eliminado")));
                  }

                  if (onAction != null) onAction!();
                }
              },
            ),
            onTap: () async {
              final updated = await Navigator.pushNamed(context, '/editPlayer', arguments: player);
              if (updated == true && onAction != null) {
                onAction!();
              }
            },
          ),
        );
      },
    );
  }
}
