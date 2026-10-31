import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:game_setter/core/utils/date_formatter.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team.dart';
import 'package:game_setter/features/match_teams/domain/formations/soccer_formations.dart';
import 'package:game_setter/features/match_teams/domain/formations/volleyball_formations.dart';
import 'package:game_setter/features/sports/data/position_repository.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

import 'match_team_soccer_diagram.dart';
import 'match_team_volleyball_diagram.dart';

/// Una pestaña por equipo y, si hay 2 o más, una pestaña extra con todos los
/// equipos en la misma imagen.
class MatchTeamsShareScreen extends StatefulWidget {
  final Match match;
  final List<MatchTeam> teams;

  const MatchTeamsShareScreen({super.key, required this.match, required this.teams});

  @override
  State<MatchTeamsShareScreen> createState() => _MatchTeamsShareScreenState();
}

class _MatchTeamsShareScreenState extends State<MatchTeamsShareScreen> with TickerProviderStateMixin {
  static const double _teamWidth = 400;
  static const double _teamHeight = 640;

  late TabController _tabController;
  final List<GlobalKey> _repaintKeys = [];
  List<Position> _positions = [];
  bool _loading = true;
  bool _sharing = false;

  bool get _hasCombined => widget.teams.length >= 2;
  int get _tabCount => widget.teams.length + (_hasCombined ? 1 : 0);
  bool _isCombinedTab(int index) => _hasCombined && index == widget.teams.length;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: _tabCount, vsync: this);
    _tabController.addListener(() => setState(() {}));

    for (int i = 0; i < _tabCount; i++) {
      _repaintKeys.add(GlobalKey());
    }

    _loadPositions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPositions() async {
    final positions = await PositionRepository().getByMatchId(widget.match.id!);

    if (!mounted) return;

    setState(() {
      _positions = positions;
      _loading = false;
    });
  }

  Future<void> _shareImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      final index = _tabController.index;
      final boundary = _repaintKeys[index].currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ImageByteFormat.png);

      if (byteData == null) return;

      final Uint8List bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final fileName = _isCombinedTab(index) ? "equipos" : "equipo_${index + 1}";
      final file = File("${dir.path}/$fileName.png");

      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String get _matchSubtitle {
    final parts = <String>[
      widget.match.sportName ?? "Partido",
      if (widget.match.date != null) DateFormatter.formatDayMonthEs(widget.match.date) ?? widget.match.date!,
      if (widget.match.time != null) widget.match.time!,
    ];
    return parts.join(" · ");
  }

  Widget _buildDiagram(MatchTeam team, {bool? showLibero}) {
    final playersMap = {for (final p in team.players) p.playerId: MatchPlayer(id: 0, matchId: widget.match.id!, playerId: p.playerId, player: p.player, positions: const [])};

    switch (widget.match.sportId) {
      case 1: // VOLLEYBALL
        return MatchTeamVolleyballDiagram(
          formation: resolveVolleyballFormation(team.formation, team.players),
          positions: _positions,
          teamPlayers: team.players,
          playersMap: playersMap,
          includeLibero: showLibero ?? teamHasLibero(team.players),
        );

      case 2: // SOCCER
        return MatchTeamSoccerDiagram(
          formation: resolveSoccerFormation(team.formation, team.players),
          positions: _positions,
          teamPlayers: team.players,
          playersMap: playersMap,
        );

      default:
        return const Center(child: Text("Deporte no soportado"));
    }
  }

  Widget _teamHeader(MatchTeam team, TextTheme textTheme) {
    return Column(
      children: [
        Text(team.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.headlineMedium),
        if (team.formation != null) ...[
          const SizedBox(height: 2),
          Text("Formación ${team.formation}", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ],
    );
  }

  Widget _footer() {
    return Text(
      "Alec - Game Setter™",
      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
    );
  }

  Widget _capturable({required int index, required double width, required double height, required Widget child}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FittedBox(
          fit: BoxFit.contain,
          child: RepaintBoundary(
            key: _repaintKeys[index],
            child: Container(
              color: Colors.white,
              width: width,
              height: height,
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamImage(MatchTeam team, int index) {
    final textTheme = Theme.of(context).textTheme;

    return _capturable(
      index: index,
      width: _teamWidth,
      height: _teamHeight,
      child: Column(
        children: [
          _teamHeader(team, textTheme),
          const SizedBox(height: 4),
          Text(_matchSubtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          Expanded(child: _buildDiagram(team)),
          const SizedBox(height: 12),
          _footer(),
        ],
      ),
    );
  }

  /// Todos los equipos en una sola imagen: 2 por fila.
  Widget _buildCombinedImage(int index) {
    final textTheme = Theme.of(context).textTheme;
    const columns = 2;
    const gap = 20.0;
    const headerHeight = 56.0;
    const footerHeight = 28.0;
    const cellWidth = _teamWidth - 40;
    const cellHeight = _teamHeight - 80;

    final rows = (widget.teams.length / columns).ceil();
    // Si algún equipo tiene líbero se reserva su lugar en todos, para que las canchas queden alineadas.
    final anyLibero = widget.teams.any((t) => teamHasLibero(t.players));
    final width = cellWidth * columns + gap * (columns - 1) + 40;
    final height = headerHeight + rows * cellHeight + (rows - 1) * gap + footerHeight + 40;

    final rowWidgets = <Widget>[];
    for (int r = 0; r < rows; r++) {
      final rowTeams = widget.teams.skip(r * columns).take(columns).toList();
      rowWidgets.add(
        SizedBox(
          height: cellHeight,
          child: Row(
            children: [
              for (int c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: gap),
                SizedBox(
                  width: cellWidth,
                  child: c < rowTeams.length
                      ? Column(
                          children: [
                            _teamHeader(rowTeams[c], textTheme),
                            const SizedBox(height: 12),
                            Expanded(child: _buildDiagram(rowTeams[c], showLibero: anyLibero)),
                          ],
                        )
                      : const SizedBox(),
                ),
              ],
            ],
          ),
        ),
      );
      if (r < rows - 1) rowWidgets.add(const SizedBox(height: gap));
    }

    return _capturable(
      index: index,
      width: width,
      height: height,
      child: Column(
        children: [
          SizedBox(
            height: headerHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.teams.length == 2 ? "${widget.teams[0].name} vs ${widget.teams[1].name}" : "Equipos", style: textTheme.headlineMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(_matchSubtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          ),
          ...rowWidgets,
          const Spacer(),
          SizedBox(height: footerHeight, child: Center(child: _footer())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final combinedLabel = widget.teams.length == 2 ? "Ambos equipos" : "Todos";
    final onCombined = _isCombinedTab(_tabController.index);

    return SafeArea(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: _tabCount > 3,
            tabAlignment: _tabCount > 3 ? TabAlignment.start : null,
            tabs: [
              ...widget.teams.map((team) => Tab(text: team.name)),
              if (_hasCombined) Tab(icon: const Icon(Icons.groups, size: 18), iconMargin: EdgeInsets.zero, text: combinedLabel),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ...widget.teams.asMap().entries.map((entry) => _buildTeamImage(entry.value, entry.key)),
                if (_hasCombined) _buildCombinedImage(widget.teams.length),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sharing ? null : _shareImage,
                icon: _sharing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.share),
                label: Text(
                  !onCombined
                      ? "Compartir imagen"
                      : widget.teams.length == 2
                      ? "Compartir ambos equipos"
                      : "Compartir todos los equipos",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
