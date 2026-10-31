import 'package:flutter/material.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/data/match_repository.dart';
import 'package:game_setter/features/matches/presentation/widgets/match_actions.dart';
import 'package:game_setter/features/matches/presentation/widgets/match_form.dart';

/// Detalle del partido: se edita aquí y tiene las mismas acciones que el menú
/// de la tarjeta (equipos, notificar, compartir, eliminar).
class EditMatchPage extends StatefulWidget {
  final Match match;
  const EditMatchPage({super.key, required this.match});

  @override
  State<EditMatchPage> createState() => _EditMatchPageState();
}

class _EditMatchPageState extends State<EditMatchPage> {
  Future<void> _run(MatchAction action) async {
    final deleted = await MatchActions.run(context, widget.match, action);
    if (deleted && mounted) Navigator.pop(context, true);
  }

  Widget _actionButton(MatchAction action) {
    return IconButton(tooltip: action.label, icon: Icon(action.icon), onPressed: () => _run(action));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Partido"),
        actions: [
          _actionButton(MatchAction.teams),
          _actionButton(MatchAction.notify),
          _actionButton(MatchAction.share),
          PopupMenuButton<MatchAction>(
            tooltip: 'Más opciones',
            onSelected: _run,
            itemBuilder: (context) => [MatchActions.menuItem(context, MatchAction.delete)],
          ),
        ],
      ),
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
