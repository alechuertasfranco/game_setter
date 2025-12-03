import 'package:flutter/material.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/data/match_repository.dart';
import 'package:game_setter/features/matches/presentation/widgets/match_form.dart';

class AddMatchPage extends StatelessWidget {
  const AddMatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agregar partido")),
      body: MatchForm(
        onSave: (Match match) async {
          // Insertar partido vacío → devuelve ID
          final matchId = await MatchRepository().insertMatch(match);
          // Limpiar jugadores previos (solo por consistencia)
          await MatchRepository().clearMatchPlayers(matchId);
          // Insertar jugadores
          for (final mp in match.players) {
            await MatchRepository().assignPlayerToMatch(matchId, mp);
          }
        },
      ),
    );
  }
}
