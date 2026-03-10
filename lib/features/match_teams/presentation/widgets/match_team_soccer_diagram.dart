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

class Formation {
  final String name;
  final int slotStart;
  final List<List<String>> lines;

  const Formation({required this.name, required this.slotStart, required this.lines});
}

class _MatchTeamSoccerDiagramState extends State<MatchTeamSoccerDiagram> {
  List<Position> _positions = [];
  late List<MatchTeamPlayer> _teamPlayers;

  final Map<int, MatchPlayer> _playersMap = {};

  final Map<String, Formation> formations = {
    "3-1-2": Formation(
      name: "3-1-2",
      slotStart: 100,
      lines: [
        ["DEL", "DEL"],
        ["MID"],
        ["DEF", "DEF", "DEF"],
        ["GK"],
      ],
    ),
    "3-2-1": Formation(
      name: "3-2-1",
      slotStart: 200,
      lines: [
        ["DEL"],
        ["MID", "MID"],
        ["DEF", "DEF", "DEF"],
        ["GK"],
      ],
    ),
    "4-3-3": Formation(
      name: "4-3-3",
      slotStart: 300,
      lines: [
        ["DEL", "DEL", "DEL"],
        ["MID", "MID", "MID"],
        ["DEF", "DEF", "DEF", "DEF"],
        ["GK"],
      ],
    ),
    "4-2-3-1": Formation(
      name: "4-2-3-1",
      slotStart: 400,
      lines: [
        ["DEL"],
        ["MID", "MID", "MID"],
        ["MID", "MID"],
        ["DEF", "DEF", "DEF", "DEF"],
        ["GK"],
      ],
    ),
    "3-2-3-2": Formation(
      name: "3-2-3-2",
      slotStart: 500,
      lines: [
        ["DEL", "DEL"],
        ["MID", "MID", "MID"],
        ["MID", "MID"],
        ["DEF", "DEF", "DEF"],
        ["GK"],
      ],
    ),
    "3-3-1": Formation(
      name: "3-3-1",
      slotStart: 600,
      lines: [
        ["DEL"],
        ["MID", "MID", "MID"],
        ["DEF", "DEF", "DEF"],
        ["GK"],
      ],
    ),
    "3-2-2": Formation(
      name: "3-2-2",
      slotStart: 700,
      lines: [
        ["DEL", "DEL"],
        ["MID", "MID"],
        ["DEF", "DEF", "DEF"],
        ["GK"],
      ],
    ),
    "3-2": Formation(
      name: "3-2",
      slotStart: 800,
      lines: [
        ["DEL", "DEL"],
        ["DEF", "DEF", "DEF"],
        ["GK"],
      ],
    ),
    "2-3": Formation(
      name: "2-3",
      slotStart: 900,
      lines: [
        ["DEL", "DEL", "DEL"],
        ["DEF", "DEF"],
        ["GK"],
      ],
    ),
    "2-2": Formation(
      name: "2-2",
      slotStart: 1000,
      lines: [
        ["DEL", "DEL"],
        ["DEF", "DEF"],
        ["GK"],
      ],
    ),
    "3-1": Formation(
      name: "3-1",
      slotStart: 1100,
      lines: [
        ["DEL"],
        ["DEF", "DEF", "DEF"],
        ["GK"],
      ],
    ),
  };

  late String selectedFormation;

  String _detectFormationFromSlots() {
    if (_teamPlayers.isEmpty) return formations.keys.first;

    final slot = _teamPlayers.first.slot;

    return formations.values.firstWhereOrNull((f) => slot >= f.slotStart && slot < f.slotStart + 20)?.name ?? formations.keys.first;
  }

  @override
  void initState() {
    super.initState();
    _teamPlayers = [...widget.players];
    selectedFormation = _detectFormationFromSlots();
    _loadInitialData();
  }

  @override
  void didUpdateWidget(covariant MatchTeamSoccerDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.availablePlayers != widget.availablePlayers) {
      _loadInitialData();
    }

    if (oldWidget.players != widget.players) {
      setState(() {
        _teamPlayers = [...widget.players];
        selectedFormation = _detectFormationFromSlots();
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

  String _firstName(Player p) {
    final parts = p.name.trim().split(RegExp(r"\s+"));
    return parts.isEmpty ? "" : parts.first;
  }

  Position? _positionByCode(String code) => _positions.firstWhereOrNull((p) => p.shortName == code);

  MatchTeamPlayer? _playerInSlot(int slot) => _teamPlayers.firstWhereOrNull((e) => e.slot == slot);

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
    setState(() => _teamPlayers.removeWhere((p) => p.slot == slot));
    widget.onPlayersChanged(_teamPlayers);
  }

  Widget _buildSlot(String code, int slot) {
    final pos = _positionByCode(code);
    if (pos == null) return const SizedBox();

    final playerItem = _playerInSlot(slot);

    String label = pos.shortName;
    Color color = Colors.white;

    if (playerItem != null) {
      final mp = _playersMap[playerItem.playerId];
      label = mp?.player != null ? _firstName(mp!.player!) : "P${playerItem.playerId}";
      color = Colors.lightGreen;
    }

    return GestureDetector(
      onTap: () => _selectPlayer(pos, slot),
      onLongPress: playerItem != null ? () => _clear(slot) : null,
      child: _PlayerCircle(label: label, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_positions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final formation = formations[selectedFormation]!;
    int slot = formation.slotStart;

    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(16)),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: SoccerFieldPainter())),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: formation.lines.map((line) {
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
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.tune),
            label: Text("Formación: $selectedFormation"),
            onPressed: () async {
              final result = await showModalBottomSheet<String>(
                context: context,
                showDragHandle: true,
                builder: (_) => ListView(
                  children: formations.keys.map((f) => ListTile(title: Text(f), onTap: () => Navigator.pop(context, f))).toList(),
                ),
              );

              if (result != null) {
                setState(() => selectedFormation = result);
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

    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
    canvas.drawCircle(Offset(size.width / 2, midY), 40, paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width / 2, 40), width: 200, height: 80), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width / 2, size.height - 40), width: 200, height: 80), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
