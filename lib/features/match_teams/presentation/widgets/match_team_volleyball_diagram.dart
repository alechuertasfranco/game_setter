import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class MatchTeamVolleyballDiagram extends StatelessWidget {
  final List<Position> positions;
  final List<MatchTeamPlayer> teamPlayers;
  final Map<int, MatchPlayer> playersMap;

  final bool use51Formation;
  final bool includeLibero;

  final void Function(Position pos, int slot)? onSlotTap;
  final void Function(Position pos, int slot)? onSlotLongPress;

  const MatchTeamVolleyballDiagram({
    super.key,
    required this.positions,
    required this.teamPlayers,
    required this.playersMap,
    required this.use51Formation,
    required this.includeLibero,
    this.onSlotTap,
    this.onSlotLongPress,
  });

  Position? _positionByCode(String code) => positions.firstWhereOrNull((p) => p.shortName == code);

  MatchTeamPlayer? _playerInSlot(Position pos, int slot) => teamPlayers.firstWhereOrNull((e) => e.positionId == pos.id && e.slot == slot);

  String _firstName(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    return parts.isEmpty ? "" : parts.first;
  }

  bool _teamHasPosition(String code) {
    final pos = _positionByCode(code);
    if (pos == null) return false;
    return teamPlayers.any((p) => p.positionId == pos.id);
  }

  Widget _buildSlot(String code, int slot) {
    final pos = _positionByCode(code);
    if (pos == null) return const SizedBox();

    final playerItem = _playerInSlot(pos, slot);

    String label = pos.shortName;
    Color color = Colors.white;

    if (playerItem != null) {
      final mp = playersMap[playerItem.playerId];

      if (mp?.player != null) {
        label = _firstName(mp!.player!.name);
        color = Colors.orange.shade300;
      }
    }

    return GestureDetector(
      onTap: () => onSlotTap?.call(pos, slot),
      onLongPress: playerItem != null ? () => onSlotLongPress?.call(pos, slot) : null,
      child: _PlayerCircle(label: label, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    int slot = 1;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(
          left: BorderSide(color: Colors.orange.shade500, width: 32),
          right: BorderSide(color: Colors.orange.shade500, width: 32),
          bottom: BorderSide(color: Colors.orange.shade500, width: 40),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: VolleyballCourtPainter())),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(height: 12),

              // FRONT ROW
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildSlot("PTA", slot++), _buildSlot("CTR", slot++), _buildSlot("ARM", slot++)]),

              const SizedBox(height: 12),
              Container(height: 2, width: double.infinity, color: Colors.orange.shade300),
              const SizedBox(height: 24),

              // BACK ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [_buildSlot(use51Formation && _teamHasPosition("OP") ? "OP" : "ARM", slot++), _buildSlot("CTR", slot++), _buildSlot("PTA", slot++)],
              ),

              const SizedBox(height: 24),

              if (includeLibero && positions.any((p) => p.shortName == "LIB")) Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildSlot("LIB", slot++)]),
            ],
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

class VolleyballCourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
