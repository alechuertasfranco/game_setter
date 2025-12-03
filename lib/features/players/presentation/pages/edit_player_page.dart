import 'package:flutter/material.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/players/data/player_repository.dart';
import 'package:game_setter/features/players/presentation/widgets/player_form.dart';

class EditPlayerPage extends StatefulWidget {
  final Player player;
  const EditPlayerPage({super.key, required this.player});

  @override
  State<EditPlayerPage> createState() => _EditPlayerPageState();
}

class _EditPlayerPageState extends State<EditPlayerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar jugador")),
      body: PlayerForm(
        initialPlayer: widget.player,
        onSave: (p, sports, positionsBySport) async {
          if (p.id == null) return;
          await PlayerRepository().updatePlayerOnly(p);
          await PlayerRepository().clearPlayerSports(p.id!);

          for (final sportId in sports) {
            final posSet = positionsBySport[sportId];
            if (posSet == null || posSet.isEmpty) {
              await PlayerRepository().assignSportToPlayer(p.id!, sportId, null);
            } else {
              for (final posId in posSet) {
                await PlayerRepository().assignSportToPlayer(p.id!, sportId, posId);
              }
            }
          }
        },
      ),
    );
  }
}
