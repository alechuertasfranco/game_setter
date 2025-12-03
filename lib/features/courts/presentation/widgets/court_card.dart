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

    String subtitle = court.phone ?? "Sin teléfono";

    // Si tiene ubicación, úsala
    if (court.location != null && court.location!.trim().isNotEmpty) {
      subtitle = court.location!;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black26,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(court.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
        leading: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withValues(alpha: 0.12)),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.location_on, color: Colors.red, size: 28),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Eliminar cancha", style: textTheme.titleMedium),
                content: Text("¿Seguro que deseas eliminar esta cancha?", style: textTheme.bodyMedium),
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
              await CourtRepository().deleteCourt(court.id!);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cancha eliminada")));
              }

              if (onAction != null) onAction!();
            }
          },
        ),
        onTap: () async {
          final updated = await Navigator.pushNamed(context, '/editCourt', arguments: court);

          if (updated == true && onAction != null) onAction!();
        },
      ),
    );
  }
}
