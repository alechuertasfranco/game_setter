import 'package:flutter/material.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/data/match_repository.dart';
import 'package:game_setter/features/matches/presentation/widgets/match_form.dart';

class EditMatchPage extends StatefulWidget {
  final Match match;
  const EditMatchPage({super.key, required this.match});

  @override
  State<EditMatchPage> createState() => _EditMatchPageState();
}

class _EditMatchPageState extends State<EditMatchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar partido")),
      body: MatchForm(
        initialMatch: widget.match,
        onSave: (m) async {
          debugPrint("Actualizando partido ID=${m.id}, sportId=${m.sportId}, courtId=${m.courtId}, date=${m.date}, time=${m.time}");
          debugPrint("Jugadores a asignar: ${m.players.map((e) => e.playerId).toList()}");

          final players = m.players;
          await MatchRepository().updateMatch(m);
          debugPrint("Partido actualizado");

          await MatchRepository().clearMatchPlayers(m.id);
          debugPrint("Jugadores previos limpiados");

          for (final player in players) {
            debugPrint("Asignando jugador ${player.playerId} al partido ${m.id}");
            await MatchRepository().assignPlayerToMatch(m.id, player);
          }

          debugPrint("Todos los jugadores asignados correctamente");
        },
      ),
    );
  }
}
