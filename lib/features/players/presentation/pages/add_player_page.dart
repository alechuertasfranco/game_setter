import 'package:flutter/material.dart';
import 'package:game_setter/features/players/data/player_repository.dart';
import 'package:game_setter/features/players/presentation/widgets/player_form.dart';

class AddPlayerPage extends StatelessWidget {
  const AddPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agregar jugador")),
      body: PlayerForm(
        onSave: (player, sports, positionsBySport) async {
          await PlayerRepository().insertPlayerOnly(player);
          for (final sportId in sports) {
            final posSet = positionsBySport[sportId];
            if (posSet == null || posSet.isEmpty) {
              await PlayerRepository().assignSportToPlayer(player.id, sportId, null);
            } else {
              for (final posId in posSet) {
                await PlayerRepository().assignSportToPlayer(player.id, sportId, posId);
              }
            }
          }
        },
      ),
    );
  }
}
