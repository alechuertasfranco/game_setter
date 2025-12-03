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
    final textTheme = Theme.of(context).textTheme;

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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          shadowColor: Colors.black26,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(player.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
            leading: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withValues(alpha: 0.12)),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.person, color: Colors.green, size: 28),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("Eliminar jugador", style: textTheme.titleMedium),
                    content: Text("¿Seguro que deseas eliminar a este jugador?", style: textTheme.bodyMedium),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("Cancelar", style: textTheme.bodyMedium),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text("Eliminar", style: textTheme.bodyMedium?.copyWith(color: Colors.redAccent)),
                      ),
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
              if (updated == true && onAction != null) onAction!();
            },
          ),
        );
      },
    );
  }
}
