import 'package:flutter/material.dart';

import 'match_team_volleyball_diagram.dart';

import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';

import 'package:game_setter/features/matches/data/match_player_repository.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';

import 'package:game_setter/features/players/domain/entities/player.dart';

import 'package:game_setter/features/sports/data/position_repository.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class MatchTeamVolleyballForm extends StatefulWidget {
  final Match match;
  final List<MatchTeamPlayer> players;
  final List<MatchPlayer> availablePlayers;
  final void Function(List<MatchTeamPlayer>) onPlayersChanged;

  const MatchTeamVolleyballForm({super.key, required this.match, required this.players, required this.availablePlayers, required this.onPlayersChanged});

  @override
  State<MatchTeamVolleyballForm> createState() => _MatchTeamVolleyballFormState();
}

class _MatchTeamVolleyballFormState extends State<MatchTeamVolleyballForm> {
  List<Position> _positions = [];

  late List<MatchTeamPlayer> _teamPlayers;

  final Map<int, MatchPlayer> _playersMap = {};

  bool use51Formation = false;
  bool includeLibero = false;

  @override
  void initState() {
    super.initState();

    _teamPlayers = [...widget.players];

    _loadInitialData();
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
      _teamPlayers.removeWhere((p) => p.positionId == pos.id && p.slot == slot);

      _teamPlayers.add(MatchTeamPlayer(id: null, teamId: 0, playerId: result.id!, positionId: pos.id, slot: slot, position: pos));
    });

    widget.onPlayersChanged(_teamPlayers);
  }

  void _clear(Position pos, int slot) {
    setState(() {
      _teamPlayers.removeWhere((p) => p.positionId == pos.id && p.slot == slot);
    });

    widget.onPlayersChanged(_teamPlayers);
  }

  @override
  Widget build(BuildContext context) {
    if (_positions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DropdownButton<bool>(
              value: use51Formation,
              items: const [
                DropdownMenuItem(value: true, child: Text("Formación 5–1")),
                DropdownMenuItem(value: false, child: Text("Formación 4–2")),
              ],
              onChanged: (v) => setState(() => use51Formation = v!),
            ),
            Row(
              children: [
                const Text("Líbero"),
                Switch(value: includeLibero, onChanged: (v) => setState(() => includeLibero = v)),
              ],
            ),
          ],
        ),
        Expanded(
          child: MatchTeamVolleyballDiagram(
            positions: _positions,
            teamPlayers: _teamPlayers,
            playersMap: _playersMap,
            use51Formation: use51Formation,
            includeLibero: includeLibero,
            onSlotTap: _selectPlayer,
            onSlotLongPress: _clear,
          ),
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
