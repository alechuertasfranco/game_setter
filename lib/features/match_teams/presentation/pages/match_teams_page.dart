// lib\features\match_teams\presentation\pages\match_teams_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:game_setter/core/utils/date_formatter.dart';
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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTeams();
  }

  Future<void> loadTeams() async {
    setState(() => isLoading = true);

    final repo = MatchTeamRepository();
    final result = await repo.getTeamsWithPlayersByMatch(widget.match.id!);

    setState(() {
      teams = result.teams;
      teamPlayers = result.playersGrouped;
      isLoading = false;
    });
  }

  void goToAddMatch() async {
    final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddMatchTeamPage(match: widget.match)));

    if (created == true) {
      loadTeams();
    }
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
