import 'package:flutter/material.dart';

import 'match_team_soccer_diagram.dart';
import 'player_slot.dart';

import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
import 'package:game_setter/features/match_teams/domain/formations/soccer_formations.dart';

import 'package:game_setter/features/matches/data/match_player_repository.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';

import 'package:game_setter/features/sports/data/position_repository.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class MatchTeamSoccerForm extends StatefulWidget {
  final Match match;
  final List<MatchTeamPlayer> players;
  final String? initialFormation;
  final List<MatchPlayer> availablePlayers;
  final void Function(List<MatchTeamPlayer>) onPlayersChanged;
  final void Function(String formation) onFormationChanged;

  const MatchTeamSoccerForm({
    super.key,
    required this.match,
    required this.players,
    required this.availablePlayers,
    required this.onPlayersChanged,
    required this.onFormationChanged,
    this.initialFormation,
  });

  @override
  State<MatchTeamSoccerForm> createState() => _MatchTeamSoccerFormState();
}

class _MatchTeamSoccerFormState extends State<MatchTeamSoccerForm> {
  List<Position> _positions = [];
  bool _loading = true;

  late List<MatchTeamPlayer> _teamPlayers;

  final Map<int, MatchPlayer> _playersMap = {};

  /// Jugadores del partido que ya están en otro equipo.
  final Set<int> _inOtherTeam = {};

  late String selectedFormation;

  @override
  void initState() {
    super.initState();

    _teamPlayers = [...widget.players];

    selectedFormation = resolveSoccerFormation(widget.initialFormation, _teamPlayers).name;
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFormationChanged(selectedFormation));

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

  void _notifyPlayers() => widget.onPlayersChanged(List.of(_teamPlayers));

  Future<void> _selectPlayer(Position pos, int slot) async {
    final current = _teamPlayers.where((p) => p.slot == slot).firstOrNull;
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

  void _clear(int slot) {
    setState(() => _teamPlayers.removeWhere((p) => p.slot == slot));
    _notifyPlayers();
  }

  /// Reubica a los jugadores en la nueva formación por posición (DEF con DEF,
  /// MID con MID...). Solo se quitan los que ya no tienen puesto libre.
  List<MatchTeamPlayer> _remap(Formation next) {
    final remaining = [..._teamPlayers]..sort((a, b) => a.slot.compareTo(b.slot));
    final result = <MatchTeamPlayer>[];

    for (final (slot, code) in next.slots) {
      final i = remaining.indexWhere((p) => p.position?.shortName == code);
      if (i == -1) continue;
      result.add(remaining.removeAt(i).copyWith(slot: slot));
    }

    return result;
  }

  Future<void> _changeFormation() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text("Formación", style: Theme.of(sheetContext).textTheme.titleLarge),
              ),
              ...formations.keys.map(
                (f) => ListTile(
                  title: Text(f),
                  subtitle: Text("${formations[f]!.slots.length} jugadores"),
                  trailing: f == selectedFormation ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () => Navigator.pop(sheetContext, f),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null || result == selectedFormation || !mounted) return;

    final remapped = _remap(formations[result]!);
    final removed = _teamPlayers.length - remapped.length;

    setState(() {
      selectedFormation = result;
      _teamPlayers = remapped;
    });

    widget.onFormationChanged(result);
    _notifyPlayers();

    if (removed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$removed jugador(es) quedaron sin puesto en la $result")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final textTheme = Theme.of(context).textTheme;
    final formation = formations[selectedFormation]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.tune, size: 18),
              label: Text("Formación $selectedFormation"),
              onPressed: _changeFormation,
            ),
            const Spacer(),
            Text("${_teamPlayers.length}/${formation.slots.length} asignados", style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),
          ],
        ),
        const SizedBox(height: 8),
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
