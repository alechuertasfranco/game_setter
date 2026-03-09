import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
import 'package:game_setter/features/matches/data/match_player_repository.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/sports/data/position_repository.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class MatchTeamSoccerDiagram extends StatefulWidget {
  final Match match;
  final List<MatchTeamPlayer> players;
  final List<MatchPlayer> availablePlayers;
  final void Function(List<MatchTeamPlayer>) onPlayersChanged;

  const MatchTeamSoccerDiagram({super.key, required this.match, required this.players, required this.availablePlayers, required this.onPlayersChanged});

  @override
  State<MatchTeamSoccerDiagram> createState() => _MatchTeamSoccerDiagramState();
}

class _MatchTeamSoccerDiagramState extends State<MatchTeamSoccerDiagram> {
  List<Position> _positions = [];
  late List<MatchTeamPlayer> _teamPlayers;

  final Map<int, MatchPlayer> _playersMap = {};
  final Set<int> _takenPlayers = {};

  /// Formaciones disponibles
  final Map<String, List<List<String>>> formations = {
    "2-2": [
      ["DEL", "DEL"],
      ["DEF", "DEF"],
      ["GK"],
    ],
    "3-2": [
      ["DEL", "DEL"],
      ["DEF", "DEF", "DEF"],
      ["GK"],
    ],
    "3-1-2": [
      ["DEL", "DEL"],
      ["MID"],
      ["DEF", "DEF", "DEF"],
      ["GK"],
    ],
    "3-2-1": [
      ["DEL"],
      ["MID", "MID"],
      ["DEF", "DEF", "DEF"],
      ["GK"],
    ],
    "3-3-1": [
      ["DEL"],
      ["MID", "MID", "MID"],
      ["DEF", "DEF", "DEF"],
      ["GK"],
    ],
    "3-2-2": [
      ["DEL", "DEL"],
      ["MID", "MID"],
      ["DEF", "DEF", "DEF"],
      ["GK"],
    ],
    "3-3-2": [
      ["DEL", "DEL"],
      ["MID", "MID", "MID"],
      ["DEF", "DEF", "DEF"],
      ["GK"],
    ],
    "3-2-3": [
      ["DEL", "DEL", "DEL"],
      ["MID", "MID"],
      ["DEF", "DEF", "DEF"],
      ["GK"],
    ],
    "4-3-2": [
      ["DEL", "DEL"],
      ["MID", "MID", "MID"],
      ["DEF", "DEF", "DEF", "DEF"],
      ["GK"],
    ],
    "4-2-3": [
      ["DEL", "DEL", "DEL"],
      ["MID", "MID"],
      ["DEF", "DEF", "DEF", "DEF"],
      ["GK"],
    ],
    "4-4-2": [
      ["DEL", "DEL"],
      ["MID", "MID", "MID", "MID"],
      ["DEF", "DEF", "DEF", "DEF"],
      ["GK"],
    ],
    "4-3-3": [
      ["DEL", "DEL", "DEL"],
      ["MID", "MID", "MID"],
      ["DEF", "DEF", "DEF", "DEF"],
      ["GK"],
    ],
    "4-2-3-1": [
      ["DEL"],
      ["MID", "MID", "MID"],
      ["MID", "MID"],
      ["DEF", "DEF", "DEF", "DEF"],
      ["GK"],
    ],
    "3-2-3-2": [
      ["DEL", "DEL"],
      ["MID", "MID", "MID"],
      ["MID", "MID"],
      ["DEF", "DEF", "DEF"],
      ["GK"],
    ],
  };

  late String selectedFormation;

  @override
  void initState() {
    super.initState();
    selectedFormation = "4-4-2";
    _teamPlayers = [...widget.players];
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final positions = await PositionRepository().getByMatchId(widget.match.id!);

    final taken = await MatchPlayerRepository().getPlayersTaken(matchId: widget.match.id!);

    final players = <int, MatchPlayer>{};

    for (final p in widget.availablePlayers) {
      final playerPositions = await MatchPlayerRepository().getPlayerPositionsForMatch(playerId: p.playerId, sportId: widget.match.sportId);
      players[p.playerId] = p.copyWith(positions: playerPositions);
    }

    setState(() {
      _positions = positions;
      _playersMap.addAll(players);
      _takenPlayers.addAll(taken);
    });
  }

  String _firstName(Player p) {
    final name = p.name.trim();
    if (name.isEmpty) return "";

    final parts = name.split(RegExp(r"\s+"));
    return parts.first;
  }

  Position? _positionByCode(String code) {
    return _positions.firstWhereOrNull((p) => p.shortName == code);
  }

  MatchTeamPlayer? _playerInSlot(Position pos, int slot) {
    return _teamPlayers.firstWhereOrNull((e) => e.positionId == pos.id && e.slot == slot);
  }

  Future<void> _selectPlayer(Position pos, int slot) async {
    final filteredPlayers = _playersMap.values.where((mp) {
      /// verificar si ya está usado
      final alreadyUsed = _teamPlayers.any((tp) => tp.playerId == mp.playerId);

      /// verificar si puede jugar esta posición
      final canPlayPosition = mp.positions.any((p) => p.id == pos.id);
      final result = canPlayPosition && !alreadyUsed;
      return result;
    }).toList();

    final result = await showModalBottomSheet<Player>(
      context: context,
      showDragHandle: true,
      builder: (_) => _PlayerSelector(players: filteredPlayers),
    );

    if (result == null) return;

    _teamPlayers.removeWhere((p) => p.positionId == pos.id && p.slot == slot);

    setState(() {
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

  Widget _buildSlot(String code, int slot) {
    final pos = _positionByCode(code);
    if (pos == null) return const SizedBox();

    final playerItem = _playerInSlot(pos, slot);
    final hasPlayer = playerItem != null;

    String label = pos.shortName;
    Color color = Colors.white;

    if (hasPlayer) {
      final mp = _playersMap[playerItem.playerId];
      final player = mp?.player;

      if (player != null) {
        label = _firstName(player);
        color = Colors.lightGreen;
      }
    }

    return GestureDetector(
      onTap: () => _selectPlayer(pos, slot),
      onLongPress: hasPlayer ? () => _clear(pos, slot) : null,
      child: _PlayerCircle(label: label, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_positions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final formation = formations[selectedFormation]!;

    int slot = 1;

    return Column(
      children: [
        /// CAMPO
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(16)),
            child: Stack(
              children: [
                /// Líneas del campo
                Positioned.fill(child: CustomPaint(painter: SoccerFieldPainter())),

                /// Jugadores
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: formation.map((line) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: line.map((code) {
                        final widget = _buildSlot(code, slot);
                        slot++;
                        return widget;
                      }).toList(),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        /// BOTÓN CAMBIAR FORMACIÓN
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.tune),
            label: Text("Formación: $selectedFormation"),
            onPressed: () async {
              final result = await showModalBottomSheet<String>(
                context: context,
                showDragHandle: true,
                builder: (_) {
                  return ListView(
                    children: formations.keys.map((f) {
                      return ListTile(title: Text(f), onTap: () => Navigator.pop(context, f));
                    }).toList(),
                  );
                },
              );

              if (result != null) {
                setState(() {
                  selectedFormation = result;
                });
              }
            },
          ),
        ),
      ],
    );
  }
}

class _PlayerCircle extends StatelessWidget {
  final String label;
  final Color color;

  const _PlayerCircle({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.black26),
        boxShadow: const [BoxShadow(blurRadius: 4, offset: Offset(0, 2), color: Colors.black26)],
      ),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
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

class SoccerFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final midY = size.height / 2;

    /// Línea central
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);

    /// Círculo central
    canvas.drawCircle(Offset(size.width / 2, midY), 40, paint);

    /// Área superior
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width / 2, 40), width: 200, height: 80), paint);

    /// Área inferior
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width / 2, size.height - 40), width: 200, height: 80), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
