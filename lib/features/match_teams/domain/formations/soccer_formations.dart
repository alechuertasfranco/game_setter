import 'package:collection/collection.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';

class Formation {
  final String name;
  final int slotStart;
  final List<List<String>> lines;

  const Formation({required this.name, required this.slotStart, required this.lines});
}

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

Formation detectFormationFromSlots(List<MatchTeamPlayer> players) {
  if (players.isEmpty) return formations.values.first;
  final slot = players.first.slot;
  return formations.values.firstWhereOrNull((f) => slot >= f.slotStart && slot < f.slotStart + 20) ?? formations.values.first;
}
