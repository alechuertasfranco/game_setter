import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
import 'package:game_setter/features/matches/data/match_player_repository.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/sports/data/position_repository.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class MatchTeamVolleyballDiagram extends StatefulWidget {
  final Match match;
  final List<MatchTeamPlayer> players;
  final List<MatchPlayer> availablePlayers;
  final void Function(List<MatchTeamPlayer>) onPlayersChanged;

  const MatchTeamVolleyballDiagram({super.key, required this.match, required this.players, required this.availablePlayers, required this.onPlayersChanged});

  @override
  State<MatchTeamVolleyballDiagram> createState() => _MatchTeamVolleyballDiagramState();
}

class _MatchTeamVolleyballDiagramState extends State<MatchTeamVolleyballDiagram> {
  List<Position> positions = [];
  late List<MatchTeamPlayer> teamPlayers;
  List<MatchPlayer> _availablePlayers = [];

  bool use51Formation = false;
  bool includeLibero = false;

  @override
  void initState() {
    super.initState();
    teamPlayers = [...widget.players];
    _loadPositions();
    _initAvailablePlayers();
  }

  @override
  void didUpdateWidget(covariant MatchTeamVolleyballDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availablePlayers != widget.availablePlayers) {
      _initAvailablePlayers();
    }
  }

  Future<void> _initAvailablePlayers() async {
    final allPlayers = [...widget.availablePlayers];
    final updatedPlayers = <MatchPlayer>[];
    final takenPlayersList = await MatchPlayerRepository().getPlayersTaken(matchId: widget.match.id!);
    final takenPlayersSet = takenPlayersList.toSet();
    final teamPlayerIds = teamPlayers.map((e) => e.playerId).toSet();

    for (var mp in allPlayers) {
      if (takenPlayersSet.contains(mp.playerId) && !teamPlayerIds.contains(mp.playerId)) continue;
      final positions = await MatchPlayerRepository().getPlayerPositionsForMatch(playerId: mp.playerId, sportId: widget.match.sportId);
      updatedPlayers.add(mp.copyWith(positions: positions));
    }

    setState(() {
      _availablePlayers = updatedPlayers;
    });
  }

  Future<void> _loadPositions() async {
    positions = await PositionRepository().getByMatchId(widget.match.id!);
    setState(() {});
  }

  String _initialsForPlayer(Player p) {
    final parts = p.name.trim().split(" ");
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return "${parts.first[0]}${parts.last[0]}".toUpperCase();
  }

  void _selectPlayerForPosition(Position pos, int slot) async {
    final theme = Theme.of(context).textTheme;

    final filteredPlayers = _availablePlayers.where((mp) {
      final alreadySelected = teamPlayers.any((tp) => tp.playerId == mp.playerId);
      final canPlayPosition = mp.positions.any((p) => p.id == pos.id);
      return !alreadySelected && canPlayPosition;
    }).toList();

    final result = await showModalBottomSheet<Player>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text("Seleccionar ${pos.name} (0$slot)", style: theme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: "Buscar jugador",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: filteredPlayers.map((mp) {
                    final player = mp.player;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(player?.name ?? "Jugador"),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => Navigator.pop(context, player),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;

    teamPlayers.removeWhere((p) => p.positionId == pos.id && p.slot == slot);

    setState(() {
      teamPlayers.add(MatchTeamPlayer(id: null, teamId: 0, playerId: result.id!, positionId: pos.id, position: pos, slot: slot));
    });

    widget.onPlayersChanged(teamPlayers);
  }

  void _clearPosition(Position pos, int slot) {
    setState(() {
      teamPlayers.removeWhere((p) => p.positionId == pos.id && p.slot == slot);
    });
    widget.onPlayersChanged(teamPlayers);
  }

  Widget _circle(Position pos, int slot) {
    final playerItem = teamPlayers.firstWhere(
      (e) => e.positionId == pos.id && e.slot == slot,
      orElse: () => MatchTeamPlayer(id: null, teamId: 0, playerId: 0, positionId: pos.id, slot: slot),
    );

    final hasPlayer = playerItem.playerId != 0;
    final textTheme = Theme.of(context).textTheme;

    String label = pos.shortName;
    Color color = Colors.grey.shade300;
    if (hasPlayer) {
      final playerItemInList = _availablePlayers.firstWhereOrNull((m) => m.playerId == playerItem.playerId);
      if (playerItemInList?.player != null) {
        label = _initialsForPlayer(playerItemInList!.player!);
        color = Colors.blue.shade300;
      } else {
        // Jugador no encontrado en _availablePlayers, usa label por defecto
        label = pos.shortName;
        color = Colors.grey.shade300;
      }
    }

    return GestureDetector(
      onTap: () => _selectPlayerForPosition(pos, slot),
      onLongPress: hasPlayer ? () => _clearPosition(pos, slot) : null,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.black26),
        ),
        alignment: Alignment.center,
        child: Text(label, style: textTheme.bodyLarge),
      ),
    );
  }

  Position pos(String code) => positions.firstWhere((p) => p.shortName == code);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (positions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DropdownButton<bool>(
              value: use51Formation,
              items: [
                DropdownMenuItem(value: true, child: Text("Formación 5–1", style: textTheme.bodyMedium)),
                DropdownMenuItem(value: false, child: Text("Formación 4–2", style: textTheme.bodyMedium)),
              ],
              onChanged: (v) => setState(() => use51Formation = v!),
            ),
            Row(
              children: [
                Text("Líbero", style: textTheme.bodyMedium),
                Transform.scale(
                  scale: 0.7,
                  child: Switch(value: includeLibero, onChanged: (v) => setState(() => includeLibero = v)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border(
                left: BorderSide(color: Colors.orange.shade500, width: 32),
                right: BorderSide(color: Colors.orange.shade500, width: 32),
                bottom: BorderSide(color: Colors.orange.shade500, width: 40),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(height: 6, color: Colors.black12),
                const SizedBox(height: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_circle(pos("PTA"), 4), _circle(pos("CTR"), 3), _circle(pos("ARM"), 2)]),
                      const SizedBox(height: 12),
                      Container(height: 2, width: double.infinity, color: Colors.orange.shade300),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _circle(pos(use51Formation ? "OP" : "ARM"), 5),
                          Column(spacing: 12, children: [_circle(pos("CTR"), 6), if (includeLibero && positions.any((p) => p.shortName == "LIB")) _circle(pos("LIB"), 7)]),
                          _circle(pos("PTA"), 1),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
