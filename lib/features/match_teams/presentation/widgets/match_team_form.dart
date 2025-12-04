// lib/features/match_teams/presentation/widgets/match_team_form.dart
import 'package:flutter/material.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
import 'package:game_setter/features/match_teams/presentation/widgets/match_team_volleyball_diagram.dart';

class MatchTeamForm extends StatefulWidget {
  final Function(MatchTeam team) onSave;
  final Match match;
  final MatchTeam? initialMatchTeam;
  final List<MatchPlayer> availablePlayers;

  const MatchTeamForm({super.key, required this.onSave, required this.match, required this.availablePlayers, this.initialMatchTeam});

  @override
  State<MatchTeamForm> createState() => _MatchTeamFormState();
}

class _MatchTeamFormState extends State<MatchTeamForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final List<MatchTeamPlayer> players = [];

  @override
  void initState() {
    super.initState();

    if (widget.initialMatchTeam != null) {
      _nameCtrl.text = widget.initialMatchTeam!.name;
      players.addAll(widget.initialMatchTeam!.players);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final team = MatchTeam(id: widget.initialMatchTeam?.id, matchId: widget.match.id!, name: _nameCtrl.text.trim(), players: players);

    widget.onSave(team);
    Navigator.pop(context, true);
  }

  void _updatePlayers(List<MatchTeamPlayer> updated) {
    setState(() {
      players
        ..clear()
        ..addAll(updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SizedBox.expand(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                /// Nombre del equipo
                TextFormField(
                  controller: _nameCtrl,
                  style: textTheme.bodyLarge,
                  decoration: InputDecoration(labelText: "Nombre del equipo"),
                  validator: (v) => (v == null || v.isEmpty) ? "El nombre es obligatorio" : null,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: MatchTeamVolleyballDiagram(match: widget.match, players: players, availablePlayers: widget.availablePlayers, onPlayersChanged: _updatePlayers),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.blue.shade800)),
                        child: Text("Guardar", style: textTheme.titleMedium?.copyWith(color: Colors.blue.shade800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
