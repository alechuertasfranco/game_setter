// lib/features/match_teams/presentation/pages/add_match_team_page.dart
import 'package:flutter/material.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team.dart';
import 'package:game_setter/features/match_teams/data/match_team_repository.dart';
import 'package:game_setter/features/match_teams/presentation/widgets/match_team_form.dart';
import 'package:game_setter/features/matches/data/match_repository.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';

class AddMatchTeamPage extends StatefulWidget {
  final Match match;

  const AddMatchTeamPage({super.key, required this.match});

  @override
  State<AddMatchTeamPage> createState() => _AddMatchTeamPageState();
}

class _AddMatchTeamPageState extends State<AddMatchTeamPage> {
  List<MatchPlayer> availablePlayers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final repo = MatchRepository();
    availablePlayers = await repo.getMatchPlayersDetailed(widget.match.id!);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agregar equipo")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : MatchTeamForm(
              match: widget.match,
              availablePlayers: availablePlayers,
              onSave: (MatchTeam team) async {
                final repo = MatchTeamRepository();
                final teamId = await repo.addTeam(team);

                await repo.clearTeamPlayers(teamId);
                for (final p in team.players) {
                  await repo.addPlayerToTeam(teamId, p);
                }
              },
            ),
    );
  }
}
