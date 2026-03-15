import 'package:flutter/material.dart';

import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/match_teams/data/match_team_repository.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team.dart';
import 'package:game_setter/features/match_teams/presentation/widgets/match_teams_share_screen.dart';

class MatchTeamsSharePage extends StatefulWidget {
  final Match match;

  const MatchTeamsSharePage({super.key, required this.match});

  @override
  State<MatchTeamsSharePage> createState() => _MatchTeamsSharePageState();
}

class _MatchTeamsSharePageState extends State<MatchTeamsSharePage> {
  late Future<List<MatchTeam>> teamsFuture;

  @override
  void initState() {
    super.initState();
    teamsFuture = _loadTeams();
  }

  Future<List<MatchTeam>> _loadTeams() async {
    final result = await MatchTeamRepository().getTeamsWithPlayersByMatch(widget.match.id!);
    return result.teams;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text("Compartir equipos", style: textTheme.titleMedium)),
      body: FutureBuilder<List<MatchTeam>>(
        future: teamsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final teams = snapshot.data!;

          if (teams.isEmpty) {
            return const Center(child: Text("No hay equipos creados"));
          }

          return MatchTeamsShareScreen(match: widget.match, teams: teams);
        },
      ),
    );
  }
}
