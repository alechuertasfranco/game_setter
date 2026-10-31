import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
import 'package:game_setter/features/match_teams/domain/formations/soccer_formations.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

import 'player_slot.dart';

const _slotAccent = Color(0xFF1B5E20);

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

  Widget _buildSlot(String code, int slot, double size) {
    final pos = _positionByCode(code);
    if (pos == null) return SizedBox(width: size, height: size);

    final tp = _playerInSlot(slot);
    final name = tp == null ? null : (playersMap[tp.playerId]?.player?.name ?? tp.player?.name ?? "Jugador");

    return PlayerSlotCircle(
      size: size,
      positionCode: code,
      playerName: name,
      accent: _slotAccent,
      onTap: onSlotTap == null ? null : () => onSlotTap!(pos, slot),
      onLongPress: tp != null && onSlotLongPress != null ? () => onSlotLongPress!(slot) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight.isFinite ? constraints.maxHeight : width * 1.4;

        final widestLine = formation.lines.map((l) => l.length).reduce(math.max);
        final size = math.min(72.0, math.min((width - 16) / (widestLine + 0.6), height / (formation.lines.length + 0.8)));

        int slot = formation.slotStart;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(16)),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: SoccerFieldPainter())),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: formation.lines.map((line) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: line.map((code) => _buildSlot(code, slot++, size)).toList(),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SoccerFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final midY = size.height / 2;
    final boxWidth = size.width * 0.55;
    final boxHeight = size.height * 0.13;

    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
    canvas.drawCircle(Offset(size.width / 2, midY), math.min(size.width, size.height) * 0.12, paint);

    canvas.drawRect(Rect.fromLTWH((size.width - boxWidth) / 2, 0, boxWidth, boxHeight), paint);
    canvas.drawRect(Rect.fromLTWH((size.width - boxWidth) / 2, size.height - boxHeight, boxWidth, boxHeight), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
