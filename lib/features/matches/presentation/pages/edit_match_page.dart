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
          final players = m.players;
          await MatchRepository().updateMatch(m);
          await MatchRepository().clearMatchPlayers(m.id!);
          for (final player in players) {
            await MatchRepository().assignPlayerToMatch(m.id!, player);
          }
        },
      ),
    );
  }
}
