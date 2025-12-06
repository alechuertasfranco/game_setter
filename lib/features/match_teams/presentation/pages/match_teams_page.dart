import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:game_setter/core/utils/date_formatter.dart';
import 'package:game_setter/features/match_sets/data/match_set_repository.dart';
import 'package:game_setter/features/match_sets/domain/entities/match_set.dart';
import 'package:game_setter/features/match_sets/presentation/pages/match_set_page.dart';
import 'package:game_setter/features/match_sets/presentation/widgets/match_set_card.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team.dart';
import 'package:game_setter/features/match_teams/data/match_team_repository.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
import 'package:game_setter/features/match_teams/presentation/widgets/match_team_card.dart';
import 'package:game_setter/features/match_teams/presentation/widgets/match_team_card_extension.dart';
import 'add_match_team_page.dart';

class MatchTeamsPage extends StatefulWidget {
  final Match match;

  const MatchTeamsPage({super.key, required this.match});

  @override
  State<MatchTeamsPage> createState() => _MatchTeamsPageState();
}

class _MatchTeamsPageState extends State<MatchTeamsPage> {
  List<MatchTeam> teams = [];
  Map<int, List<MatchTeamPlayer>> teamPlayers = {};
  List<MatchSet> sets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTeams();
  }

  Future<void> loadTeams() async {
    setState(() => isLoading = true);

    final result = await MatchTeamRepository().getTeamsWithPlayersByMatch(widget.match.id!);
    final setsResult = await MatchSetRepository().getSetsByMatchId(widget.match.id!);

    setState(() {
      teams = result.teams;
      teamPlayers = result.playersGrouped;
      sets = setsResult;
      isLoading = false;
    });
  }

  void goToAddTeam() async {
    final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddMatchTeamPage(match: widget.match)));

    if (created == true) loadTeams();
  }

  void startSet() async {
    if (teams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Se necesitan al menos 2 equipos')));
      return;
    }

    final selected = await showModalBottomSheet<List<int>>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _TeamSelectionSheet(teams: teams),
    );

    if (selected == null || selected.length != 2) return;
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchSetPage(matchId: widget.match.id!, team1Id: selected[0], team2Id: selected[1], onSave: () => loadTeams()),
      ),
    );

    loadTeams();
  }

  void showSets() {
    if (sets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay sets creados')));
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: sets.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MatchSetCard(
                matchSet: sets[i],
                onRefresh: () {
                  Navigator.pop(context);
                  loadTeams();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Equipos - ${DateFormatter.formatDayMonthEs(widget.match.date)}", style: textTheme.headlineSmall?.copyWith(color: Colors.white)),
        backgroundColor: Colors.blueGrey,
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: 10,
        overlayOpacity: 0.5,
        children: [
          SpeedDialChild(child: const Icon(Icons.group_add, size: 20), label: 'Agregar equipo', labelStyle: textTheme.bodySmall, onTap: goToAddTeam),
          SpeedDialChild(child: const Icon(Icons.sports_score, size: 20), label: 'Iniciar set', labelStyle: textTheme.bodySmall, onTap: startSet),
          SpeedDialChild(child: const Icon(Icons.list, size: 20), label: 'Ver sets', labelStyle: textTheme.bodySmall, onTap: showSets),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : teams.isEmpty
          ? Center(child: Text('No hay equipos aún', style: textTheme.bodyLarge))
          : SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 48),
                itemCount: teams.length,
                itemBuilder: (_, i) {
                  final team = teams[i];
                  final players = teamPlayers[team.id] ?? [];
                  return MatchTeamCard(match: widget.match, team: team, players: players).onCardAction(loadTeams);
                },
              ),
            ),
    );
  }
}

class _TeamSelectionSheet extends StatefulWidget {
  final List<MatchTeam> teams;

  const _TeamSelectionSheet({required this.teams});

  @override
  State<_TeamSelectionSheet> createState() => _TeamSelectionSheetState();
}

class _TeamSelectionSheetState extends State<_TeamSelectionSheet> {
  final List<int> selected = [];

  void toggle(int id) {
    setState(() {
      if (selected.contains(id)) {
        selected.remove(id);
      } else if (selected.length < 2) {
        selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Selecciona 2 equipos", style: textTheme.titleLarge),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: widget.teams.map((team) {
                  final isSelected = selected.contains(team.id);

                  return Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: isSelected ? Colors.blue : Colors.grey.shade300, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(team.name),
                      trailing: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Colors.blue : null),
                      onTap: () => toggle(team.id!),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: selected.length == 2 ? () => Navigator.pop(context, selected) : null, child: const Text("Iniciar set")),
            ),
          ],
        ),
      ),
    );
  }
}
