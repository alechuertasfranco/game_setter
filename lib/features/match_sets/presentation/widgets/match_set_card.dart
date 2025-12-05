import 'package:flutter/material.dart';
import 'package:game_setter/features/match_sets/data/match_set_repository.dart';
import 'package:game_setter/features/match_sets/domain/entities/match_set.dart';
import 'package:game_setter/features/match_sets/presentation/pages/match_set_page.dart';

class MatchSetCard extends StatelessWidget {
  final MatchSet matchSet;
  final VoidCallback? onRefresh;

  const MatchSetCard({super.key, required this.matchSet, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final winnerTeamId = matchSet.winnerTeam?.id;
    final finished = matchSet.finished;
    final mvpName = matchSet.decisivePlayer?.name ?? "No asignado";
    final borderStyle = finished ? Border.all(color: Colors.grey.shade300, width: 2) : Border.all(color: Colors.blueAccent, width: 2, style: BorderStyle.solid);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: borderStyle, color: Colors.white),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ClipRect(
          child: Dismissible(
            key: ValueKey(matchSet.id),
            background: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.blue,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.edit, color: Colors.white),
              ),
            ),
            secondaryBackground: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchSetPage(matchId: matchSet.matchId, team1Id: matchSet.team1Id, team2Id: matchSet.team2Id, setId: matchSet.id),
                  ),
                );
                if (onRefresh != null) onRefresh!();
                return false;
              } else if (direction == DismissDirection.endToStart) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("Eliminar periodo", style: textTheme.titleMedium),
                    content: Text("¿Seguro que deseas eliminar este periodo?", style: textTheme.bodyMedium),
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
                  await MatchSetRepository().deleteMatchSet(matchSet.id);
                  if (!context.mounted) return true;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Periodo eliminado")));
                  if (onRefresh != null) onRefresh!();
                }
              }
              return false;
            },
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              trailing: const SizedBox.shrink(),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, color: winnerTeamId == matchSet.team1?.id ? Colors.amber : Colors.grey.shade400, size: 20),
                  const SizedBox(width: 4),
                  Text(matchSet.team1?.name ?? "Equipo 1", style: textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Text("${matchSet.team1Score}", style: textTheme.bodyMedium),
                  const SizedBox(width: 6),
                  Text("-", style: textTheme.titleMedium),
                  const SizedBox(width: 6),
                  Text("${matchSet.team2Score}", style: textTheme.bodyMedium),
                  const SizedBox(width: 8),
                  Text(matchSet.team2?.name ?? "Equipo 2", style: textTheme.titleMedium),
                  const SizedBox(width: 4),
                  Icon(Icons.emoji_events, color: winnerTeamId == matchSet.team2?.id ? Colors.amber : Colors.grey.shade400, size: 20),
                ],
              ),
              children: [
                const SizedBox(height: 6),
                Text("MVP: $mvpName", style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
