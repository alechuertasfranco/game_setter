import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
import 'package:game_setter/features/matches/data/match_player_repository.dart';
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
  List<MatchPlayer> _availablePlayers = [];
  List<int> _takenPlayers = [];

  bool use51Formation = false;
  bool includeLibero = false;

  @override
  void initState() {
    super.initState();
    teamPlayers = [...widget.players];
    _loadPositions();
    _initAvailablePlayers();
  }

  @override
  void didUpdateWidget(covariant MatchTeamVolleyballDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availablePlayers != widget.availablePlayers) {
      _initAvailablePlayers();
    }
  }

  Future<void> _initAvailablePlayers() async {
    final allPlayers = [...widget.availablePlayers];
    final updatedPlayers = <MatchPlayer>[];
    final takenPlayersList = await MatchPlayerRepository().getPlayersTaken(matchId: widget.match.id!);

    for (var mp in allPlayers) {
      final positions = await MatchPlayerRepository().getPlayerPositionsForMatch(playerId: mp.playerId, sportId: widget.match.sportId);
      updatedPlayers.add(mp.copyWith(positions: positions));
    }

    setState(() {
      _availablePlayers = updatedPlayers;
      _takenPlayers = takenPlayersList;
      _updateFormation();
    });
  }

  void _updateFormation() {
    final hasOP = teamPlayers.any((tp) {
      final posObj = positions.firstWhereOrNull((p) => p.id == tp.positionId);
      return posObj?.shortName == "OP";
    });

    if (hasOP && !use51Formation) setState(() => use51Formation = true);
  }

  Future<void> _loadPositions() async {
    positions = await PositionRepository().getByMatchId(widget.match.id!);
    setState(() {});
  }

  String _initialsForPlayer(Player p) {
    final parts = p.name.trim().split(" ");

    if (parts.length == 1) {
      return parts.first[0].toUpperCase() + parts.first.substring(1);
    }

    final first = parts.first;
    return first[0].toUpperCase() + first.substring(1).toLowerCase();
  }

  void _selectPlayerForPosition(Position pos, int slot) async {
    final theme = Theme.of(context).textTheme;

    List<MatchPlayer> getFor(String type) {
      return _availablePlayers.where((mp) {
        final alreadySelected = teamPlayers.any((tp) => tp.playerId == mp.playerId);
        final canPlayPosition = mp.positions.any((p) => p.id == pos.id);
        final isTaken = _takenPlayers.contains(mp.playerId);
        final isUnconfirmed = mp.attended != true;

        if (!canPlayPosition) return false;

        return switch (type) {
          "added" => alreadySelected,
          "taken" => isTaken && !alreadySelected,
          "unconfirmed" => isUnconfirmed,
          _ => !alreadySelected && !isTaken && !isUnconfirmed,
        };
      }).toList();
    }

    Widget buildDividerTitle(String text) {
      return Row(
        children: [
          const Expanded(child: Divider(thickness: 0.6)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(text, style: theme.bodySmall),
          ),
          const Expanded(child: Divider(thickness: 0.6)),
        ],
      );
    }

    Widget buildFilterTile(String label, String type) {
      return ExpansionTile(
        visualDensity: VisualDensity.compact,
        tilePadding: const EdgeInsets.symmetric(vertical: 0),
        childrenPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        trailing: const SizedBox.shrink(),
        title: buildDividerTitle(label),
        children: getFor(type).map((mp) => _playerTile(mp, context, pos, slot)).toList(),
      );
    }

    final Player? result = await showModalBottomSheet<Player>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return SafeArea(
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    children: [
                      Text("Seleccionar ${pos.name} (0$slot)", style: theme.titleLarge),
                      const SizedBox(height: 12),

                      Expanded(
                        child: ListView(
                          children: [
                            ...getFor("all").map((mp) => _playerTile(mp, context, pos, slot)),
                            buildFilterTile("Mostrar de otros equipos", "taken"),
                            buildFilterTile("Mostrar no confirmados", "unconfirmed"),
                            buildFilterTile("Mostrar agregados", "added"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    teamPlayers.removeWhere((p) => p.positionId == pos.id && p.slot == slot);

    setState(() {
      teamPlayers.add(MatchTeamPlayer(id: null, teamId: 0, playerId: result.id!, positionId: pos.id, position: pos, slot: slot));
      _updateFormation();
    });

    widget.onPlayersChanged(teamPlayers);
  }

  Widget _playerTile(MatchPlayer mp, BuildContext context, Position pos, int slot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8, right: 16),
      child: ListTile(
        leading: Icon(mp.attended == true ? Icons.person : Icons.person_outline, color: Colors.grey.shade800),
        title: Text(mp.player?.name ?? "Jugador"),
        trailing: const Icon(Icons.add_circle_outline),
        onTap: () => Navigator.pop(context, mp.player),
      ),
    );
  }

  void _clearPosition(Position pos, int slot) {
    setState(() {
      teamPlayers.removeWhere((p) => p.positionId == pos.id && p.slot == slot);
      _updateFormation();
    });
    widget.onPlayersChanged(teamPlayers);
  }

  Widget _circle(Position pos, int slot) {
    final playerItem = teamPlayers.firstWhere(
      (e) => e.positionId == pos.id && e.slot == slot,
      orElse: () => MatchTeamPlayer(id: null, teamId: 0, playerId: 0, positionId: pos.id, slot: slot),
    );

    final hasPlayer = playerItem.playerId != 0;
    final textTheme = Theme.of(context).textTheme;

    String label = pos.shortName;
    Color color = Colors.grey.shade300;
    if (hasPlayer) {
      final playerItemInList = _availablePlayers.firstWhereOrNull((m) => m.playerId == playerItem.playerId);
      if (playerItemInList?.player != null) {
        label = _initialsForPlayer(playerItemInList!.player!);
        color = Colors.blue.shade300;
      } else {
        label = pos.shortName;
        color = Colors.grey.shade300;
      }
    }

    return GestureDetector(
      onTap: () => _selectPlayerForPosition(pos, slot),
      onLongPress: hasPlayer ? () => _clearPosition(pos, slot) : null,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.black26),
        ),
        alignment: Alignment.center,
        child: Text(label, style: textTheme.bodySmall),
      ),
    );
  }

  Position pos(String code) => positions.firstWhere((p) => p.shortName == code);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (positions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(mainAxisSize: MainAxisSize.min, children: [_buildHeader(textTheme), const SizedBox(height: 12), _buildCourt()]),
          ),
        );
      },
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButton<bool>(
          value: use51Formation,
          items: [
            DropdownMenuItem(value: true, child: Text("Formación 5–1", style: textTheme.bodyMedium)),
            DropdownMenuItem(value: false, child: Text("Formación 4–2", style: textTheme.bodyMedium)),
          ],
          onChanged: (v) => setState(() => use51Formation = v!),
        ),
        Row(
          children: [
            Text("Líbero", style: textTheme.bodyMedium),
            Transform.scale(
              scale: 0.7,
              child: Switch(value: includeLibero, onChanged: (v) => setState(() => includeLibero = v)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCourt() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(
          left: BorderSide(color: Colors.orange.shade500, width: 32),
          right: BorderSide(color: Colors.orange.shade500, width: 32),
          bottom: BorderSide(color: Colors.orange.shade500, width: 40),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 6, color: Colors.black12),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 350),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_circle(pos("PTA"), 4), _circle(pos("CTR"), 3), _circle(pos("ARM"), 2)]),
                const SizedBox(height: 12),
                Container(height: 2, width: double.infinity, color: Colors.orange.shade300),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _circle(pos(use51Formation ? "OP" : "ARM"), 5),
                    Column(spacing: 12, children: [_circle(pos("CTR"), 6), if (includeLibero && positions.any((p) => p.shortName == "LIB")) _circle(pos("LIB"), 7)]),
                    _circle(pos("PTA"), 1),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
