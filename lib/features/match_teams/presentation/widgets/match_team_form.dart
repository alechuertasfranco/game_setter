// lib/features/match_teams/presentation/widgets/match_team_form.dart
import 'package:flutter/material.dart';
import 'package:game_setter/features/match_teams/presentation/widgets/match_team_soccer_form.dart';
import 'package:game_setter/features/match_teams/presentation/widgets/match_team_volleyball_form.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';

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
  String? formation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialMatchTeam != null) {
      _nameCtrl.text = widget.initialMatchTeam!.name;
      players.addAll(widget.initialMatchTeam!.players);
      formation = widget.initialMatchTeam!.formation;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final team = MatchTeam(id: widget.initialMatchTeam?.id, matchId: widget.match.id!, name: _nameCtrl.text.trim(), formation: formation, players: List.of(players));

    await widget.onSave(team);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _updatePlayers(List<MatchTeamPlayer> updated) {
    setState(() {
      players
        ..clear()
        ..addAll(updated);
    });
  }

  void _updateFormation(String value) => formation = value;

  Widget _buildSportDiagram() {
    switch (widget.match.sportId) {
      case 1: // Vóley
        return MatchTeamVolleyballForm(
          match: widget.match,
          players: players,
          initialFormation: formation,
          availablePlayers: widget.availablePlayers,
          onPlayersChanged: _updatePlayers,
          onFormationChanged: _updateFormation,
        );

      case 2: // Fútbol
        return MatchTeamSoccerForm(
          match: widget.match,
          players: players,
          initialFormation: formation,
          availablePlayers: widget.availablePlayers,
          onPlayersChanged: _updatePlayers,
          onFormationChanged: _updateFormation,
        );

      default:
        return const Center(child: Text("Deporte no soportado"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SizedBox.expand(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                /// Nombre del equipo
                TextFormField(
                  controller: _nameCtrl,
                  style: textTheme.bodyLarge,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: "Nombre del equipo"),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "El nombre es obligatorio" : null,
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildSportDiagram()),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.blue.shade800)),
                    child: Text("Guardar", style: textTheme.titleMedium?.copyWith(color: Colors.blue.shade800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
