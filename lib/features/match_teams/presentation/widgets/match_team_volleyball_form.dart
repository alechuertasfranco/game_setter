import 'package:flutter/material.dart';

import 'match_team_volleyball_diagram.dart';
import 'player_slot.dart';

import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
import 'package:game_setter/features/match_teams/domain/formations/volleyball_formations.dart';

import 'package:game_setter/features/matches/data/match_player_repository.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';

import 'package:game_setter/features/sports/data/position_repository.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class MatchTeamVolleyballForm extends StatefulWidget {
  final Match match;
  final List<MatchTeamPlayer> players;
  final String? initialFormation;
  final List<MatchPlayer> availablePlayers;
  final void Function(List<MatchTeamPlayer>) onPlayersChanged;
  final void Function(String formation) onFormationChanged;

  const MatchTeamVolleyballForm({
    super.key,
    required this.match,
    required this.players,
    required this.availablePlayers,
    required this.onPlayersChanged,
    required this.onFormationChanged,
    this.initialFormation,
  });

  @override
  State<MatchTeamVolleyballForm> createState() => _MatchTeamVolleyballFormState();
}

class _MatchTeamVolleyballFormState extends State<MatchTeamVolleyballForm> {
  List<Position> _positions = [];
  bool _loading = true;

  late List<MatchTeamPlayer> _teamPlayers;
  late VolleyballFormation _formation;
  late bool _includeLibero;

  final Map<int, MatchPlayer> _playersMap = {};

  /// Jugadores del partido que ya están en otro equipo.
  final Set<int> _inOtherTeam = {};

  @override
  void initState() {
    super.initState();

    _teamPlayers = [...widget.players];
    _formation = resolveVolleyballFormation(widget.initialFormation, _teamPlayers);
    _includeLibero = teamHasLibero(_teamPlayers);

    // Equipos antiguos no tenían formación guardada: se fija la deducida.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFormationChanged(_formation.name));

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final positions = await PositionRepository().getByMatchId(widget.match.id!);
    final ownIds = widget.players.map((p) => p.playerId).toSet();
    final taken = (await MatchPlayerRepository().getPlayersTaken(matchId: widget.match.id!)).where((id) => !ownIds.contains(id)).toSet();

    final players = <int, MatchPlayer>{};

    for (final p in widget.availablePlayers) {
      final pos = await MatchPlayerRepository().getPlayerPositionsForMatch(playerId: p.playerId, sportId: widget.match.sportId);

      players[p.playerId] = p.copyWith(positions: pos, player: p.player);
    }

    if (!mounted) return;

    setState(() {
      _positions = positions;
      _loading = false;

      _playersMap
        ..clear()
        ..addAll(players);

      _inOtherTeam
        ..clear()
        ..addAll(taken);
    });
  }

  Position? _positionByCode(String code) {
    for (final p in _positions) {
      if (p.shortName == code) return p;
    }
    return null;
  }

  void _notifyPlayers() => widget.onPlayersChanged(List.of(_teamPlayers));

  Future<void> _onSlotTap(Position pos, int slot) async {
    final current = playerInSlot(_teamPlayers, slot);
    final usedElsewhere = _teamPlayers.where((tp) => tp.slot != slot).map((tp) => tp.playerId).toSet();
    final freePlayers = _playersMap.values.where((mp) => !usedElsewhere.contains(mp.playerId) && mp.playerId != current?.playerId).toList();

    final currentName = current == null ? null : (_playersMap[current.playerId]?.player?.name ?? current.player?.name);

    final result = await showPlayerSlotSheet(context: context, position: pos, freePlayers: freePlayers, currentPlayerName: currentName, inOtherTeam: _inOtherTeam);

    if (result == null || !mounted) return;

    setState(() {
      _teamPlayers.removeWhere((p) => p.slot == slot);

      if (!result.clear) {
        final player = result.player!;
        _teamPlayers.add(MatchTeamPlayer(id: null, teamId: 0, playerId: player.id!, player: player, positionId: pos.id, slot: slot, position: pos));
      }
    });

    _notifyPlayers();
  }

  void _clearSlot(int slot) {
    setState(() => _teamPlayers.removeWhere((p) => p.slot == slot));
    _notifyPlayers();
  }

  /// Cambia la formación sin perder jugadores: quien estaba en un puesto que
  /// cambia de posición (2.º armador ↔ opuesto) se queda con la nueva posición.
  void _changeFormation(String name) {
    final next = volleyballFormations[name];
    if (next == null || next.name == _formation.name) return;

    final moved = <String>[];

    setState(() {
      for (final vs in next.allSlots) {
        final i = _teamPlayers.indexWhere((p) => p.slot == vs.slot);
        if (i == -1) continue;

        final tp = _teamPlayers[i];
        if (tp.position?.shortName == vs.code) continue;

        final newPos = _positionByCode(vs.code);
        if (newPos == null) continue;

        _teamPlayers[i] = tp.copyWith(positionId: newPos.id, position: newPos);
        final name = _playersMap[tp.playerId]?.player?.name ?? tp.player?.name;
        if (name != null) moved.add("$name ahora juega de ${newPos.name}");
      }

      _formation = next;
    });

    widget.onFormationChanged(next.name);
    _notifyPlayers();

    if (moved.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(moved.join("\n"))));
    }
  }

  void _toggleLibero(bool value) {
    final hadLibero = teamHasLibero(_teamPlayers);

    setState(() {
      _includeLibero = value;
      if (!value) _teamPlayers.removeWhere((p) => p.slot == liberoSlot.slot);
    });

    _notifyPlayers();

    if (!value && hadLibero) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Se quitó al líbero del equipo")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final textTheme = Theme.of(context).textTheme;
    final assigned = _teamPlayers.length;
    final total = 6 + (_includeLibero ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SegmentedButton<String>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: volleyballFormations.keys.map((name) => ButtonSegment<String>(value: name, label: Text(name))).toList(),
              selected: {_formation.name},
              onSelectionChanged: (s) => _changeFormation(s.first),
            ),
            const Spacer(),
            FilterChip(
              label: const Text("Líbero"),
              selected: _includeLibero,
              onSelected: _toggleLibero,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "${_formation.description} · $assigned/$total asignados",
          style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: MatchTeamVolleyballDiagram(
            formation: _formation,
            positions: _positions,
            teamPlayers: _teamPlayers,
            playersMap: _playersMap,
            includeLibero: _includeLibero,
            onSlotTap: _onSlotTap,
            onSlotLongPress: _clearSlot,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Toca un puesto para asignar o cambiar jugador. Mantén presionado para quitarlo.",
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
