import 'package:flutter/material.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
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

  bool use51Formation = true;
  bool includeLibero = true;

  @override
  void initState() {
    super.initState();
    teamPlayers = [...widget.players];
    _loadPositions();
  }

  Future<void> _loadPositions() async {
    positions = await PositionRepository().getByMatchId(widget.match.id!);
    setState(() {});
  }

  String _initialsForPlayer(Player p) {
    final parts = p.name.trim().split(" ");
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return "${parts.first[0]}${parts.last[0]}".toUpperCase();
  }

  void _selectPlayerForPosition(Position pos) async {
    final theme = Theme.of(context).textTheme;

    final result = await showModalBottomSheet<Player>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text("Seleccionar jugador", style: theme.titleLarge),

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
                  children: widget.availablePlayers.map((mp) {
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
        );
      },
    );

    if (result == null) return;

    teamPlayers.removeWhere((p) => p.positionId == pos.id);

    setState(() {
      teamPlayers.add(MatchTeamPlayer(id: null, teamId: 0, playerId: result.id!, positionId: pos.id, position: pos));
    });

    widget.onPlayersChanged(teamPlayers);
  }

  void _clearPosition(Position pos) {
    setState(() {
      teamPlayers.removeWhere((p) => p.positionId == pos.id);
    });
    widget.onPlayersChanged(teamPlayers);
  }

  Widget _circle(Position pos) {
    final playerItem = teamPlayers.firstWhere((e) => e.positionId == pos.id, orElse: () => MatchTeamPlayer(id: null, teamId: 0, playerId: 0, positionId: pos.id));

    final hasPlayer = playerItem.playerId != 0;
    final textTheme = Theme.of(context).textTheme;

    String label = pos.shortName;
    Color color = Colors.grey.shade300;

    if (hasPlayer) {
      final player = widget.availablePlayers.firstWhere((m) => m.playerId == playerItem.playerId).player;
      label = _initialsForPlayer(player!);
      color = Colors.blue.shade300;
    }

    return GestureDetector(
      onTap: () => _selectPlayerForPosition(pos),
      onLongPress: hasPlayer ? () => _clearPosition(pos) : null,
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
              items: const [
                DropdownMenuItem(value: true, child: Text("Formación 5–1")),
                DropdownMenuItem(value: false, child: Text("Formación 4–2")),
              ],
              onChanged: (v) => setState(() => use51Formation = v!),
            ),
            Row(
              children: [
                const Text("Líbero"),
                Switch(value: includeLibero, onChanged: (v) => setState(() => includeLibero = v)),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border(
              left: BorderSide(color: Colors.orange.shade500, width: 32),
              right: BorderSide(color: Colors.orange.shade500, width: 32),
              bottom: BorderSide(color: Colors.orange.shade500, width: 32),
            ),
          ),
          padding: const EdgeInsets.all(12),

          child: Column(
            children: [
              Container(height: 6, color: Colors.black12),

              const SizedBox(height: 24),

              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_circle(pos("PTA")), _circle(pos("CTR")), _circle(pos("ARM"))]),

              const SizedBox(height: 12),

              Container(height: 2, width: double.infinity, color: Colors.orange.shade300),

              const SizedBox(height: 12),

              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_circle(pos(use51Formation ? "OP" : "ARM")), _circle(pos("CTR")), _circle(pos("PTA"))]),

              const SizedBox(height: 24),

              if (includeLibero && positions.any((p) => p.shortName == "LIB")) _circle(pos("LIB")),
            ],
          ),
        ),
      ],
    );
  }
}
