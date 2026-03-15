import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:game_setter/core/utils/date_formatter.dart';
import 'package:game_setter/core/utils/match_share_formatter.dart';

import 'package:game_setter/features/matches/data/match_repository.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';

import 'package:game_setter/features/sports/domain/entities/sport.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback? onAction;

  const MatchCard({super.key, required this.match, this.onAction});

  Future<Map<String, dynamic>> _loadMatchStats() {
    return MatchRepository().getMatchStatistics(match.id!);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    void handleAction(String action) async {
      if (action == 'teams') {
        Navigator.pushNamed(context, '/matchTeams', arguments: match);
      } else if (action == 'notify') {
        Navigator.pushNamed(context, '/matchNotifications', arguments: match);
      } else if (action == 'share') {
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.text_snippet),
                      title: const Text("Compartir detalles"),
                      onTap: () async {
                        Navigator.pop(context);

                        final players = await MatchRepository().getMatchPlayersDetailed(match.id!);

                        final message = MatchShareFormatter.generateMessage(match, players);

                        await Share.share(message);
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.image),
                      title: const Text("Compartir equipos"),
                      onTap: () async {
                        Navigator.pop(context);

                        // aquí luego generaremos la imagen
                        Navigator.pushNamed(context, '/matchTeamsShare', arguments: match);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else if (action == 'delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Eliminar partido", style: textTheme.titleMedium),
            content: Text("¿Seguro que deseas eliminar este partido?", style: textTheme.bodyMedium),
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
          await MatchRepository().clearMatchPlayers(match.id!);
          await MatchRepository().deleteMatch(match.id!);

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Partido eliminado"), duration: Duration(milliseconds: 500)));

          if (onAction != null) onAction!();
        }
      }
    }

    return FutureBuilder(
      future: _loadMatchStats(),
      builder: (context, snapshot) {
        int attended = 0;
        int paid = 0;

        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null && snapshot.data!.isNotEmpty) {
          final data = snapshot.data!;
          attended = data["attended"] ?? 0;
          paid = data["paid"] ?? 0;
        }

        final title = "${match.sportName} - ${DateFormatter.formatDayMonthEs(match.date)}";

        final subtitle = "$attended confirmados - $paid pagados";

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          shadowColor: Colors.black26,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
            leading: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withValues(alpha: 0.12)),
              padding: const EdgeInsets.all(8),
              child: Sport.getIcon(match.sportName),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => handleAction(value),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'teams',
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    spacing: 12,
                    children: [
                      const Icon(Icons.person_outline, color: Colors.green, size: 20),
                      Text('Equipos', style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'notify',
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    spacing: 12,
                    children: [
                      const Icon(Icons.notifications_outlined, color: Colors.orange, size: 20),
                      Text('Notificación', style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    spacing: 12,
                    children: [
                      const Icon(Icons.share_outlined, color: Colors.blue, size: 20),
                      Text('Compartir', style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    spacing: 12,
                    children: [
                      const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      Text('Eliminar', style: textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () async {
              final updated = await Navigator.pushNamed(context, '/editMatch', arguments: match);

              if (updated == true && onAction != null) onAction!();
            },
          ),
        );
      },
    );
  }
}
