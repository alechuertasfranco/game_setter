import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
import 'package:game_setter/features/match_teams/domain/formations/soccer_formations.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class MatchTeamSoccerDiagram extends StatelessWidget {
  final Formation formation;
  final List<Position> positions;
  final List<MatchTeamPlayer> teamPlayers;
  final Map<int, MatchPlayer> playersMap;

  final void Function(Position pos, int slot)? onSlotTap;
  final void Function(int slot)? onSlotLongPress;

  const MatchTeamSoccerDiagram({
    super.key,
    required this.formation,
    required this.positions,
    required this.teamPlayers,
    required this.playersMap,
    this.onSlotTap,
    this.onSlotLongPress,
  });

  Position? _positionByCode(String code) => positions.firstWhereOrNull((p) => p.shortName == code);

  MatchTeamPlayer? _playerInSlot(int slot) => teamPlayers.firstWhereOrNull((e) => e.slot == slot);

  String _firstName(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    return parts.isEmpty ? "" : parts.first;
  }

  Widget _buildSlot(String code, int slot) {
    final pos = _positionByCode(code);
    if (pos == null) return const SizedBox();

    final playerItem = _playerInSlot(slot);

    String label = pos.shortName;
    Color color = Colors.white;

    if (playerItem != null) {
      final mp = playersMap[playerItem.playerId];
      label = mp?.player != null ? _firstName(mp!.player!.name) : "P${playerItem.playerId}";
      color = Colors.lightGreen;
    }

    return GestureDetector(
      onTap: () => onSlotTap?.call(pos, slot),
      onLongPress: playerItem != null ? () => onSlotLongPress?.call(slot) : null,
      child: _PlayerCircle(label: label, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    int slot = formation.slotStart;

    return Container(
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
