import 'package:collection/collection.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';

/// Un puesto en la cancha: el slot que se guarda en BD y el código de posición.
class VolleySlot {
  final int slot;
  final String code;

  const VolleySlot(this.slot, this.code);
}

class VolleyballFormation {
  final String name;
  final String description;

  /// Fila de ataque, de izquierda a derecha (zonas 4, 3, 2).
  final List<VolleySlot> front;

  /// Fila de defensa, de izquierda a derecha (zonas 5, 6, 1).
  final List<VolleySlot> back;

  const VolleyballFormation({required this.name, required this.description, required this.front, required this.back});

  List<VolleySlot> get allSlots => [...front, ...back];
}

/// Slot fijo del líbero (fuera de la rotación).
const VolleySlot liberoSlot = VolleySlot(7, 'LIB');

/// Los slots 1–6 se mantienen iguales en ambas formaciones para que los
/// equipos guardados antes de esta versión sigan cargando bien.
/// La única diferencia es el slot 4: segundo armador (4-2) u opuesto (5-1),
/// siempre en diagonal al armador del slot 3.
const Map<String, VolleyballFormation> volleyballFormations = {
  '5-1': VolleyballFormation(
    name: '5-1',
    description: '1 armador, 1 opuesto, 2 puntas, 2 centrales',
    front: [VolleySlot(1, 'PTA'), VolleySlot(2, 'CTR'), VolleySlot(3, 'ARM')],
    back: [VolleySlot(4, 'OP'), VolleySlot(5, 'CTR'), VolleySlot(6, 'PTA')],
  ),
  '4-2': VolleyballFormation(
    name: '4-2',
    description: '2 armadores, 2 puntas, 2 centrales',
    front: [VolleySlot(1, 'PTA'), VolleySlot(2, 'CTR'), VolleySlot(3, 'ARM')],
    back: [VolleySlot(4, 'ARM'), VolleySlot(5, 'CTR'), VolleySlot(6, 'PTA')],
  ),
};

/// Devuelve la formación guardada o, para equipos antiguos, la deduce:
/// si alguien juega de opuesto es 5-1, si no 4-2.
VolleyballFormation resolveVolleyballFormation(String? saved, List<MatchTeamPlayer> players) {
  final byName = saved != null ? volleyballFormations[saved] : null;
  if (byName != null) return byName;

  final hasOpposite = players.any((p) => p.position?.shortName == 'OP');
  return volleyballFormations[hasOpposite ? '5-1' : '4-2']!;
}

bool teamHasLibero(List<MatchTeamPlayer> players) => players.any((p) => p.slot == liberoSlot.slot);

MatchTeamPlayer? playerInSlot(List<MatchTeamPlayer> players, int slot) => players.firstWhereOrNull((p) => p.slot == slot);
