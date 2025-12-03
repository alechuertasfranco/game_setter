import 'package:flutter/material.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/players/data/player_repository.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onAction;

  const PlayerCard({super.key, required this.player, this.onAction});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Future<bool?> handleDismiss(DismissDirection direction) async {
      if (direction == DismissDirection.startToEnd) {
        // Deslizar a la derecha -> Editar
        final updated = await Navigator.pushNamed(context, '/editPlayer', arguments: player);
        if (updated == true && onAction != null) onAction!();
        return false; // No eliminar
      } else if (direction == DismissDirection.endToStart) {
        // Deslizar a la izquierda -> Eliminar
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
          if (player.id == null) return true;
          await PlayerRepository().clearPlayerSports(player.id!);
          await PlayerRepository().deletePlayer(player.id!);

          if (!context.mounted) return true;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jugador eliminado")));

          if (onAction != null) onAction!();
        }

        return confirm;
      }
      return false;
    }

    return Dismissible(
      key: ValueKey(player.id),
      direction: DismissDirection.horizontal,
      background: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          color: Colors.blue,
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      ),
      secondaryBackground: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.redAccent,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
      ),
      confirmDismiss: handleDismiss,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        shadowColor: Colors.black26,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Text(player.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(player.subtitle!, style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
          leading: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withAlpha(30)),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.person, color: Colors.green, size: 28),
          ),
          onTap: () async {
            final updated = await Navigator.pushNamed(context, '/editPlayer', arguments: player);
            if (updated == true && onAction != null) onAction!();
          },
        ),
      ),
    );
  }
}
