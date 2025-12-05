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

  void goToAddMatch() async {
    final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddMatchTeamPage(match: widget.match)));

    if (created == true) {
      loadTeams();
    }
  }

  void startSet() async {
    if (teams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Se necesitan al menos 2 equipos para iniciar un set')));
      return;
    }

    final teamIds = teams.take(2).map((t) => t.id!).toList();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchSetPage(matchId: widget.match.id!, team1Id: teamIds[0], team2Id: teamIds[1]),
      ),
    );

    loadTeams();
  }

  void showSets() {
    if (sets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay sets creados todavía')));
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.builder(
          itemCount: sets.length,
          itemBuilder: (context, i) {
            final set = sets[i];
            return MatchSetCard(matchSet: set);
          },
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
        elevation: 4,
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        overlayOpacity: 0.5,
        spacing: 10,
        children: [
          SpeedDialChild(child: const Icon(Icons.group_add, size: 20), label: 'Agregar equipo', labelStyle: textTheme.bodySmall, onTap: goToAddMatch, shape: const CircleBorder()),
          SpeedDialChild(child: const Icon(Icons.sports_score, size: 20), label: 'Iniciar set', labelStyle: textTheme.bodySmall, onTap: startSet, shape: const CircleBorder()),
          SpeedDialChild(child: const Icon(Icons.list, size: 20), label: 'Ver sets', labelStyle: textTheme.bodySmall, onTap: showSets, shape: const CircleBorder()),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : teams.isEmpty
          ? Center(child: Text('No hay equipos aún', style: textTheme.bodyLarge))
          : SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.all(12).copyWith(bottom: 48),
                itemCount: teams.length,
                itemBuilder: (context, i) {
                  final team = teams[i];
                  final players = teamPlayers[team.id] ?? [];
                  return MatchTeamCard(match: widget.match, team: team, players: players).onCardAction(loadTeams);
                },
              ),
            ),
    );
  }
}
