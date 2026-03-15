import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team.dart';
import 'package:game_setter/features/match_teams/domain/formations/soccer_formations.dart';
import 'package:game_setter/features/sports/data/position_repository.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

import 'match_team_soccer_diagram.dart';
import 'match_team_volleyball_diagram.dart';

class MatchTeamsShareScreen extends StatefulWidget {
  final Match match;
  final List<MatchTeam> teams;

  const MatchTeamsShareScreen({super.key, required this.match, required this.teams});

  @override
  State<MatchTeamsShareScreen> createState() => _MatchTeamsShareScreenState();
}

class _MatchTeamsShareScreenState extends State<MatchTeamsShareScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<GlobalKey> _repaintKeys = [];
  List<Position> _positions = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: widget.teams.length, vsync: this);

    for (int i = 0; i < widget.teams.length; i++) {
      _repaintKeys.add(GlobalKey());
    }

    _loadPositions();
  }

  Future<void> _loadPositions() async {
    final positions = await PositionRepository().getByMatchId(widget.match.id!);

    if (!mounted) return;

    setState(() {
      _positions = positions;
    });
  }

  Future<void> _shareImage() async {
    final index = _tabController.index;
    final boundary = _repaintKeys[index].currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ImageByteFormat.png);

    if (byteData == null) return;

    final Uint8List bytes = byteData.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/team_${index + 1}.png");

    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)]);
  }

  Widget _buildDiagram(MatchTeam team) {
    final playersMap = {for (final p in team.players) p.playerId: MatchPlayer(id: 0, matchId: widget.match.id!, playerId: p.playerId, player: p.player, positions: const [])};

    switch (widget.match.sportId) {
      case 1: // VOLLEYBALL
        final liberoPosition = _positions.firstWhereOrNull((p) => p.shortName == "LIB");
        final hasLibero = liberoPosition != null && team.players.any((tp) => tp.positionId == liberoPosition.id);
        return MatchTeamVolleyballDiagram(positions: _positions, teamPlayers: team.players, playersMap: playersMap, use51Formation: true, includeLibero: hasLibero);

      case 2: // SOCCER
        final formation = detectFormationFromSlots(team.players);
        return MatchTeamSoccerDiagram(formation: formation, positions: _positions, teamPlayers: team.players, playersMap: playersMap);

      default:
        return const Center(child: Text("Deporte no soportado"));
    }
  }

  Widget _buildShareContent(MatchTeam team, int index) {
    const double canvasWidth = 400;
    const double canvasHeight = 640;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: RepaintBoundary(
              key: _repaintKeys[index],
              child: Container(
                color: Colors.white,
                child: SizedBox(
                  width: canvasWidth,
                  height: canvasHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(team.name, textAlign: TextAlign.center, style: textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text(widget.match.sportName ?? "Formación", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                        const SizedBox(height: 20),
                        Expanded(child: _buildDiagram(team)),
                        const SizedBox(height: 16),
                        Text(
                          "Alec - Game Setter™",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_positions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: widget.teams.map((team) => Tab(text: team.name)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: widget.teams.asMap().entries.map((entry) => Center(child: _buildShareContent(entry.value, entry.key))).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(onPressed: _shareImage, icon: const Icon(Icons.share), label: const Text("Compartir imagen")),
            ),
          ),
        ],
      ),
    );
  }
}
