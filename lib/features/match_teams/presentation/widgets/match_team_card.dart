// lib\features\match_teams\presentation\widgets\match_team_card.dart
import 'package:flutter/material.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team.dart';
import 'package:game_setter/features/match_teams/data/match_team_repository.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';

class MatchTeamCard extends StatelessWidget {
  final Match match;
  final MatchTeam team;
  final List<MatchTeamPlayer> players;
  final VoidCallback? onAction;

  const MatchTeamCard({super.key, required this.match, required this.team, required this.players, this.onAction});

  void _showPlayersDetail(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Jugadores de ${team.name}', style: textTheme.titleLarge),
              const SizedBox(height: 24),
              if (players.isEmpty)
                Text('Sin jugadores', style: textTheme.bodyMedium)
              else
                ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: players.length,
                  itemBuilder: (_, index) {
                    final p = players[index];
                    final pos = p.position?.shortName ?? 'Sin posición';
                    final name = p.player?.name ?? 'Desconocido';
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      child: Row(
                        children: [
                          Text(pos, style: textTheme.bodyLarge),
                          const SizedBox(width: 8),
                          Expanded(child: Text(name, style: textTheme.bodyLarge)),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.blue.shade800)),
                child: Text("Cerrar", style: textTheme.titleSmall?.copyWith(color: Colors.blue.shade800)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = '${players.length} jugador(es)';

    return Dismissible(
      key: ValueKey(team.id),
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
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          final updated = await Navigator.pushNamed(context, '/editTeam', arguments: {'match': match, 'team': team});
          if (updated == true && onAction != null) {
            onAction!();
          }
          return false;
        } else if (direction == DismissDirection.endToStart) {
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
          if (confirm == true && team.id != null) {
            await MatchTeamRepository().clearTeamPlayers(team.id!);
            await MatchTeamRepository().deleteTeam(team.id!);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Equipo eliminado")));
              if (onAction != null) onAction!();
            }
          }
          return confirm;
        }
        return false;
      },
      child: GestureDetector(
        onLongPress: () => _showPlayersDetail(context),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          shadowColor: Colors.black26,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(team.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
            leading: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueGrey.withAlpha(30)),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.groups, color: Colors.blueGrey, size: 28),
            ),
            onTap: () async {
              final updated = await Navigator.pushNamed(context, '/editTeam', arguments: {'match': match, 'team': team});
              if (updated == true && onAction != null) {
                onAction!();
              }
            },
          ),
        ),
      ),
    );
  }
}
