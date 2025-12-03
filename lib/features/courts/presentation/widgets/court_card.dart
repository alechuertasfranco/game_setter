import 'package:flutter/material.dart';
import 'package:game_setter/features/courts/domain/entities/court.dart';
import 'package:game_setter/features/courts/data/court_repository.dart';

class CourtCard extends StatelessWidget {
  final Court court;
  final VoidCallback? onAction;

  const CourtCard({super.key, required this.court, this.onAction});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Future<bool?> handleDismiss(DismissDirection direction) async {
      if (direction == DismissDirection.startToEnd) {
        // Deslizar a la derecha -> Editar
        final updated = await Navigator.pushNamed(context, '/editCourt', arguments: court);
        if (updated == true && onAction != null) onAction!();
        return false; // No eliminar
      } else if (direction == DismissDirection.endToStart) {
        // Deslizar a la izquierda -> Eliminar
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Eliminar ${court.name}", style: textTheme.titleMedium),
            content: Text("¿Seguro que deseas eliminar ${court.name}?", style: textTheme.bodyMedium),
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
          if (court.id == null) return true;
          await CourtRepository().deleteCourt(court.id!);

          if (!context.mounted) return true;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jugador eliminado")));

          if (onAction != null) onAction!();
        }

        return confirm;
      }
      return false;
    }

    return Dismissible(
      key: ValueKey(court.id),
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
          title: Text(court.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(court.subtitle ?? "", style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
          leading: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withValues(alpha: 0.12)),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.location_on, color: Colors.red, size: 28),
          ),
          onTap: () async {
            final updated = await Navigator.pushNamed(context, '/editCourt', arguments: court);
            if (updated == true && onAction != null) onAction!();
          },
        ),
      ),
    );
  }
}
