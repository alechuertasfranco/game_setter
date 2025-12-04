import 'package:flutter/material.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team.dart';
import 'package:game_setter/features/match_teams/data/match_team_repository.dart';

class MatchTeamCard extends StatelessWidget {
  final MatchTeam team;
  final VoidCallback? onAction;

  const MatchTeamCard({super.key, required this.team, this.onAction});

  Future<int> _loadPlayersCount() async {
    final players = await MatchTeamRepository().getPlayersByTeam(team.id!);
    return players.length;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    void handleAction(String action) async {
      if (action == 'edit') {
        final updated = await Navigator.pushNamed(context, '/editTeam', arguments: team);
        if (updated == true && onAction != null) onAction!();
      } else if (action == 'delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Eliminar equipo", style: textTheme.titleMedium),
            content: Text("¿Seguro que deseas eliminar este equipo?", style: textTheme.bodyMedium),
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
          await MatchTeamRepository().deleteTeam(team.id!);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Equipo eliminado"), duration: Duration(milliseconds: 500)));
          if (onAction != null) onAction!();
        }
      }
    }

    return FutureBuilder<int>(
      future: _loadPlayersCount(),
      builder: (context, snapshot) {
        final playerCount = snapshot.data ?? 0;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          shadowColor: Colors.black26,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(team.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text("$playerCount jugadores", style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => handleAction(value),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SizedBox(
                    child: Row(
                      spacing: 12,
                      children: [
                        const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                        Text('Editar', style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SizedBox(
                    child: Row(
                      spacing: 12,
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        Text('Eliminar', style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(context, '/teamPlayers', arguments: team);
            },
          ),
        );
      },
    );
  }
}
