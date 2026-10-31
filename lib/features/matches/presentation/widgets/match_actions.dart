import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:game_setter/core/utils/match_share_formatter.dart';
import 'package:game_setter/features/matches/data/match_repository.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';

/// Acciones de un partido. Las usan tanto el menú de la tarjeta en la lista
/// como la pantalla de detalle, para que se comporten igual en ambos sitios.
enum MatchAction {
  teams('Equipos', Icons.groups_outlined, Colors.green),
  notify('Notificar', Icons.notifications_outlined, Colors.orange),
  share('Compartir', Icons.share_outlined, Colors.blue),
  delete('Eliminar', Icons.delete_outline, Colors.redAccent);

  final String label;
  final IconData icon;
  final Color color;

  const MatchAction(this.label, this.icon, this.color);
}

class MatchActions {
  MatchActions._();

  static PopupMenuItem<MatchAction> menuItem(BuildContext context, MatchAction action) {
    return PopupMenuItem(
      value: action,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        spacing: 12,
        children: [
          Icon(action.icon, color: action.color, size: 20),
          Text(action.label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// Ejecuta la acción. Devuelve true si el partido fue eliminado.
  static Future<bool> run(BuildContext context, Match match, MatchAction action) async {
    switch (action) {
      case MatchAction.teams:
        await Navigator.pushNamed(context, '/matchTeams', arguments: match);
        return false;
      case MatchAction.notify:
        await Navigator.pushNamed(context, '/matchNotifications', arguments: match);
        return false;
      case MatchAction.share:
        await showShareSheet(context, match);
        return false;
      case MatchAction.delete:
        return confirmDelete(context, match);
    }
  }

  static Future<void> showShareSheet(BuildContext context, Match match) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text("Compartir", style: textTheme.titleLarge),
                ),
                ListTile(
                  leading: const Icon(Icons.text_snippet_outlined),
                  title: const Text("Detalles del partido"),
                  subtitle: const Text("Fecha, hora, cancha y jugadores en texto"),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final players = await MatchRepository().getMatchPlayersDetailed(match.id!);
                    final message = MatchShareFormatter.generateMessage(match, players);
                    await Share.share(message);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text("Equipos en imagen"),
                  subtitle: const Text("Cada equipo por separado o todos juntos"),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, '/matchTeamsShare', arguments: match);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<bool> confirmDelete(BuildContext context, Match match) async {
    final textTheme = Theme.of(context).textTheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Eliminar partido", style: textTheme.titleMedium),
        content: Text("¿Seguro que deseas eliminar este partido?", style: textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text("Cancelar", style: textTheme.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text("Eliminar", style: textTheme.bodyMedium?.copyWith(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return false;

    await MatchRepository().clearMatchPlayers(match.id!);
    await MatchRepository().deleteMatch(match.id!);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Partido eliminado"), duration: Duration(milliseconds: 1200)));
    }

    return true;
  }
}
