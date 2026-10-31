import 'package:flutter/material.dart';

import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

/// "Juan Pérez" → "Juan P." para que quepa en el círculo sin perder quién es.
String shortPlayerName(String name) {
  final parts = name.trim().split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return "";
  if (parts.length == 1) return parts.first;
  return "${parts.first} ${parts[1][0].toUpperCase()}.";
}

/// Círculo de un puesto en la cancha. Vacío muestra "+" y la posición;
/// ocupado muestra el nombre del jugador y la posición debajo.
class PlayerSlotCircle extends StatelessWidget {
  final double size;
  final String positionCode;
  final String? playerName;
  final Color accent;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PlayerSlotCircle({super.key, required this.size, required this.positionCode, required this.accent, this.playerName, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final filled = playerName != null;
    final interactive = onTap != null;

    return Semantics(
      button: interactive,
      label: filled ? "$playerName, $positionCode" : "Asignar $positionCode",
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? accent : Colors.white,
            border: Border.all(color: filled ? Colors.white : accent, width: 2),
            boxShadow: const [BoxShadow(blurRadius: 4, offset: Offset(0, 2), color: Colors.black26)],
          ),
          padding: EdgeInsets.all(size * 0.12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: filled
                  ? [
                      Text(
                        shortPlayerName(playerName!),
                        maxLines: 1,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        positionCode,
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                      ),
                    ]
                  : [
                      if (interactive) Icon(Icons.add, color: accent, size: 18),
                      Text(
                        positionCode,
                        style: TextStyle(fontWeight: FontWeight.w700, color: accent, fontSize: 13),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Resultado del selector: un jugador elegido o la orden de vaciar el puesto.
class SlotSelection {
  final Player? player;
  final bool clear;

  const SlotSelection.player(Player this.player) : clear = false;
  const SlotSelection.clear() : player = null, clear = true;
}

/// Abre el selector de jugador para un puesto. Muestra primero a quienes juegan
/// esa posición y luego al resto, para no quedar bloqueado si nadie la tiene.
Future<SlotSelection?> showPlayerSlotSheet({
  required BuildContext context,
  required Position position,
  required List<MatchPlayer> freePlayers,
  String? currentPlayerName,
  Set<int> inOtherTeam = const {},
}) {
  final eligible = freePlayers.where((mp) => mp.positions.any((p) => p.id == position.id)).toList();
  final others = freePlayers.where((mp) => !mp.positions.any((p) => p.id == position.id)).toList();

  // Primero los libres, al final los que ya están en otro equipo; dentro de cada grupo, por nombre.
  int byName(MatchPlayer a, MatchPlayer b) {
    final taken = (inOtherTeam.contains(a.playerId) ? 1 : 0) - (inOtherTeam.contains(b.playerId) ? 1 : 0);
    if (taken != 0) return taken;
    return (a.player?.name ?? "").toLowerCase().compareTo((b.player?.name ?? "").toLowerCase());
  }
  eligible.sort(byName);
  others.sort(byName);

  return showModalBottomSheet<SlotSelection>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final textTheme = Theme.of(sheetContext).textTheme;
      final maxHeight = MediaQuery.of(sheetContext).size.height * 0.75;

      Widget playerTile(MatchPlayer mp, {required bool highlighted}) {
        final positions = mp.positions.map((p) => p.shortName).join(", ");
        final taken = inOtherTeam.contains(mp.playerId);
        final subtitle = [positions.isEmpty ? "Sin posiciones asignadas" : positions, if (taken) "Ya está en otro equipo"].join(" · ");
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: highlighted ? Colors.blue.shade50 : Colors.grey.shade200,
            child: Icon(Icons.person, color: highlighted ? Colors.blue.shade700 : Colors.grey.shade600),
          ),
          title: Text(mp.player?.name ?? "Jugador", style: textTheme.bodyLarge),
          subtitle: Text(subtitle, style: textTheme.bodySmall?.copyWith(color: taken ? Colors.orange.shade800 : null)),
          trailing: const Icon(Icons.add_circle_outline),
          onTap: mp.player == null ? null : () => Navigator.pop(sheetContext, SlotSelection.player(mp.player!)),
        );
      }

      Widget sectionHeader(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text, style: textTheme.labelMedium?.copyWith(color: Colors.blueGrey)),
      );

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("${position.name} (${position.shortName})", style: textTheme.titleLarge),
              ),
              if (currentPlayerName != null)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.person_remove_outlined, color: Colors.redAccent),
                  ),
                  title: Text("Quitar a $currentPlayerName", style: textTheme.bodyLarge?.copyWith(color: Colors.redAccent)),
                  onTap: () => Navigator.pop(sheetContext, const SlotSelection.clear()),
                ),
              sectionHeader("JUEGAN DE ${position.name.toUpperCase()}"),
              if (eligible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "Ningún jugador libre tiene la posición ${position.name}. Puedes elegir a otro jugador abajo o asignarle la posición desde Jugadores.",
                    style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                  ),
                )
              else
                ...eligible.map((mp) => playerTile(mp, highlighted: true)),
              if (others.isNotEmpty) ...[sectionHeader("OTROS JUGADORES"), ...others.map((mp) => playerTile(mp, highlighted: false))],
              if (eligible.isEmpty && others.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text("Todos los jugadores del partido ya están en un puesto.", style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
                ),
            ],
          ),
        ),
      );
    },
  );
}
