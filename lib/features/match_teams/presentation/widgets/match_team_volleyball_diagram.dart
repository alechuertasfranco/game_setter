import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
import 'package:game_setter/features/match_teams/domain/formations/volleyball_formations.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

import 'player_slot.dart';

const _floorColor = Color(0xFF2B5F7E);
const _courtColor = Color(0xFFEFA25A);
const _slotAccent = Color(0xFF1565C0);

/// Media cancha de vóley vista desde arriba: la red arriba, la línea de ataque
/// a un tercio y el líbero (si hay) en la zona libre de abajo.
class MatchTeamVolleyballDiagram extends StatelessWidget {
  final VolleyballFormation formation;
  final List<Position> positions;
  final List<MatchTeamPlayer> teamPlayers;
  final Map<int, MatchPlayer> playersMap;
  final bool includeLibero;

  final void Function(Position pos, int slot)? onSlotTap;
  final void Function(int slot)? onSlotLongPress;

  const MatchTeamVolleyballDiagram({
    super.key,
    required this.formation,
    required this.positions,
    required this.teamPlayers,
    required this.playersMap,
    required this.includeLibero,
    this.onSlotTap,
    this.onSlotLongPress,
  });

  Position? _positionByCode(String code) => positions.firstWhereOrNull((p) => p.shortName == code);

  String? _playerName(MatchTeamPlayer? tp) {
    if (tp == null) return null;
    return playersMap[tp.playerId]?.player?.name ?? tp.player?.name ?? "Jugador";
  }

  Widget _slot(VolleySlot vs, double size) {
    final pos = _positionByCode(vs.code);
    if (pos == null) return SizedBox(width: size, height: size);

    final tp = playerInSlot(teamPlayers, vs.slot);

    return PlayerSlotCircle(
      size: size,
      positionCode: vs.code,
      playerName: _playerName(tp),
      accent: _slotAccent,
      onTap: onSlotTap == null ? null : () => onSlotTap!(pos, vs.slot),
      onLongPress: tp != null && onSlotLongPress != null ? () => onSlotLongPress!(vs.slot) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight.isFinite ? constraints.maxHeight : width * 1.25;

        const sidePad = 16.0;
        const topPad = 22.0;
        final showLibero = includeLibero && _positionByCode(liberoSlot.code) != null;

        final size = math.min(72.0, math.min((width - sidePad * 2) / 3.6, height / (showLibero ? 5.2 : 4.0)));
        final bottomPad = showLibero ? size + 28 : 16.0;

        final court = Rect.fromLTRB(sidePad, topPad, width - sidePad, height - bottomPad);

        final columnsX = [court.left + court.width / 6, court.center.dx, court.right - court.width / 6];
        final frontY = court.top + court.height / 6;
        final backY = court.top + court.height * 2 / 3;

        Widget placed(VolleySlot vs, double cx, double cy) {
          return Positioned(left: cx - size / 2, top: cy - size / 2, child: _slot(vs, size));
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: VolleyballCourtPainter(court: court))),
                for (int i = 0; i < formation.front.length; i++) placed(formation.front[i], columnsX[i], frontY),
                for (int i = 0; i < formation.back.length; i++) placed(formation.back[i], columnsX[i], backY),
                if (showLibero) placed(liberoSlot, court.center.dx, court.bottom + 14 + size / 2),
              ],
            ),
          ),
        );
      },
    );
  }
}

class VolleyballCourtPainter extends CustomPainter {
  final Rect court;

  VolleyballCourtPainter({required this.court});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _floorColor);
    canvas.drawRect(court, Paint()..color = _courtColor);

    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRect(court, line);

    // Línea de ataque (3 m de 9 m).
    final attackY = court.top + court.height / 3;
    canvas.drawLine(Offset(court.left, attackY), Offset(court.right, attackY), line);

    // Red con sus postes.
    final net = Paint()
      ..color = const Color(0xFF1F2933)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(court.left - 8, court.top), Offset(court.right + 8, court.top), net);

    final post = Paint()..color = const Color(0xFF1F2933);
    canvas.drawCircle(Offset(court.left - 8, court.top), 5, post);
    canvas.drawCircle(Offset(court.right + 8, court.top), 5, post);
  }

  @override
  bool shouldRepaint(covariant VolleyballCourtPainter oldDelegate) => oldDelegate.court != court;
}
