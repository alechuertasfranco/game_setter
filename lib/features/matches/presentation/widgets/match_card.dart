import 'package:flutter/material.dart';

import 'package:game_setter/core/utils/date_formatter.dart';

import 'package:game_setter/features/matches/data/match_repository.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';

import 'package:game_setter/features/sports/domain/entities/sport.dart';

import 'match_actions.dart';

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

    Future<void> handleAction(MatchAction action) async {
      final deleted = await MatchActions.run(context, match, action);
      if (deleted && onAction != null) onAction!();
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
            trailing: PopupMenuButton<MatchAction>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Opciones',
              onSelected: handleAction,
              itemBuilder: (context) => MatchAction.values.map((a) => MatchActions.menuItem(context, a)).toList(),
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
