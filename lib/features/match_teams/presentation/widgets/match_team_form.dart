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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Text("Datos del equipo", style: textTheme.titleLarge),
                  const SizedBox(height: 16),

                  /// Nombre del equipo
                  TextFormField(
                    controller: _nameCtrl,
                    style: textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: "Nombre del equipo",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? "El nombre es obligatorio" : null,
                  ),

                  const SizedBox(height: 28),

                  Text("Formación / Posiciones", style: textTheme.titleLarge),
                  const SizedBox(height: 12),

                  /// DIAGRAMA — ocupa todo el espacio disponible
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox.expand(
                          child: MatchTeamVolleyballDiagram(match: widget.match, players: players, availablePlayers: widget.availablePlayers, onPlayersChanged: _updatePlayers),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// BOTÓN: estilo minimalista
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _save,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text("Guardar", style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
