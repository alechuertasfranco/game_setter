// lib/features/match_teams/presentation/pages/edit_match_team_page.dart
import 'package:flutter/material.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team.dart';
import 'package:game_setter/features/match_teams/data/match_team_repository.dart';
import 'package:game_setter/features/match_teams/presentation/widgets/match_team_form.dart';
import 'package:game_setter/features/matches/data/match_repository.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';

class EditMatchTeamPage extends StatefulWidget {
  final Match match;
  final MatchTeam team;
  const EditMatchTeamPage({super.key, required this.match, required this.team});

  @override
  State<EditMatchTeamPage> createState() => _EditMatchTeamPageState();
}

class _EditMatchTeamPageState extends State<EditMatchTeamPage> {
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
      appBar: AppBar(title: const Text("Editar equipo")),
      body: MatchTeamForm(
        availablePlayers: availablePlayers,
        match: widget.match,
        initialMatchTeam: widget.team,
        onSave: (m) async {
          final repo = MatchTeamRepository();

          await repo.updateTeam(m);
          await repo.clearTeamPlayers(m.id!);

          for (final player in m.players) {
            await repo.addPlayerToTeam(m.id!, player);
          }
        },
      ),
    );
  }
}
