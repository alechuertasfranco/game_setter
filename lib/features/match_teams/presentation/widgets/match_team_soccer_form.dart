import 'package:flutter/material.dart';

import 'match_team_soccer_diagram.dart';

import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
import 'package:game_setter/features/match_teams/domain/formations/soccer_formations.dart';

import 'package:game_setter/features/matches/data/match_player_repository.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';

import 'package:game_setter/features/players/domain/entities/player.dart';

import 'package:game_setter/features/sports/data/position_repository.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class MatchTeamSoccerForm extends StatefulWidget {
  final Match match;
  final List<MatchTeamPlayer> players;
  final List<MatchPlayer> availablePlayers;
  final void Function(List<MatchTeamPlayer>) onPlayersChanged;

  const MatchTeamSoccerForm({super.key, required this.match, required this.players, required this.availablePlayers, required this.onPlayersChanged});

  @override
  State<MatchTeamSoccerForm> createState() => _MatchTeamSoccerFormState();
}

class _MatchTeamSoccerFormState extends State<MatchTeamSoccerForm> {
  List<Position> _positions = [];

  late List<MatchTeamPlayer> _teamPlayers;

  final Map<int, MatchPlayer> _playersMap = {};

  late String selectedFormation;

  @override
  void initState() {
    super.initState();

    _teamPlayers = [...widget.players];

    selectedFormation = detectFormationFromSlots(_teamPlayers).name;

    _loadInitialData();
  }

  @override
  void didUpdateWidget(covariant MatchTeamSoccerForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.availablePlayers != widget.availablePlayers) {
      _loadInitialData();
    }

    if (oldWidget.players != widget.players) {
      setState(() {
        _teamPlayers = [...widget.players];
        selectedFormation = detectFormationFromSlots(_teamPlayers).name;
      });
    }
  }

  Future<void> _loadInitialData() async {
    final positions = await PositionRepository().getByMatchId(widget.match.id!);

    final players = <int, MatchPlayer>{};

    for (final p in widget.availablePlayers) {
      final pos = await MatchPlayerRepository().getPlayerPositionsForMatch(playerId: p.playerId, sportId: widget.match.sportId);

      players[p.playerId] = p.copyWith(positions: pos, player: p.player);
    }

    if (!mounted) return;

    setState(() {
      _positions = positions;

      _playersMap
        ..clear()
        ..addAll(players);
    });
  }

  Future<void> _selectPlayer(Position pos, int slot) async {
    final players = _playersMap.values.where((mp) {
      final used = _teamPlayers.any((tp) => tp.playerId == mp.playerId);
      final canPlay = mp.positions.any((p) => p.id == pos.id);

      return canPlay && !used;
    }).toList();

    final result = await showModalBottomSheet<Player>(
      context: context,
      showDragHandle: true,
      builder: (_) => _PlayerSelector(players: players),
    );

    if (result == null) return;

    setState(() {
      _teamPlayers.removeWhere((p) => p.slot == slot);

      _teamPlayers.add(MatchTeamPlayer(id: null, teamId: 0, playerId: result.id!, positionId: pos.id, slot: slot, position: pos));
    });

    widget.onPlayersChanged(_teamPlayers);
  }

  void _clear(int slot) {
    setState(() {
      _teamPlayers.removeWhere((p) => p.slot == slot);
    });

    widget.onPlayersChanged(_teamPlayers);
  }

  Future<void> _changeFormation() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        children: formations.keys.map((f) => ListTile(title: Text(f), onTap: () => Navigator.pop(context, f))).toList(),
      ),
    );

    if (result != null) {
      setState(() {
        selectedFormation = result;
        _teamPlayers.clear();
      });

      widget.onPlayersChanged(_teamPlayers);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_positions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final formation = formations[selectedFormation]!;

    return Column(
      children: [
        Expanded(
          child: MatchTeamSoccerDiagram(
            formation: formation,
            positions: _positions,
            teamPlayers: _teamPlayers,
            playersMap: _playersMap,
            onSlotTap: _selectPlayer,
            onSlotLongPress: _clear,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: ElevatedButton.icon(icon: const Icon(Icons.tune), label: Text("Formación: $selectedFormation"), onPressed: _changeFormation),
        ),
      ],
    );
  }
}

class _PlayerSelector extends StatelessWidget {
  final List<MatchPlayer> players;

  const _PlayerSelector({required this.players});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: players.map((mp) {
        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(mp.player?.name ?? "Jugador"),
          subtitle: Text(mp.positions.map((p) => p.shortName).join(", ")),
          trailing: const Icon(Icons.add_circle_outline),
          onTap: () => Navigator.pop(context, mp.player),
        );
      }).toList(),
    );
  }
}
