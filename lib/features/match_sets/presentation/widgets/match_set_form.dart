import 'package:flutter/material.dart';
import 'package:game_setter/features/match_sets/data/match_set_repository.dart';
import 'package:game_setter/features/match_sets/domain/entities/match_set.dart';
import 'package:game_setter/features/match_teams/data/match_team_repository.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';

class MatchSetForm extends StatefulWidget {
  final int matchSetId;
  final VoidCallback onSave;

  const MatchSetForm({super.key, required this.matchSetId, required this.onSave});

  @override
  State<MatchSetForm> createState() => _MatchSetFormState();
}

class _MatchSetFormState extends State<MatchSetForm> with SingleTickerProviderStateMixin {
  late MatchSet matchSet;
  bool isLoading = true;

  List<MatchTeamPlayer> team1Players = [];
  List<MatchTeamPlayer> team2Players = [];
  int? selectedMvpId;

  final MatchSetRepository repo = MatchSetRepository();
  final MatchTeamRepository teamRepository = MatchTeamRepository();

  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200), lowerBound: 0.88, upperBound: 1.0);

    _buttonScale = CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack);

    _buttonController.value = 1.0;

    _loadSet();
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _loadSet() async {
    setState(() => isLoading = true);

    matchSet = await repo.findSetById(widget.matchSetId);
    team1Players = await teamRepository.getPlayersByTeam(matchSet.team1Id);
    team2Players = await teamRepository.getPlayersByTeam(matchSet.team2Id);

    setState(() {
      selectedMvpId = matchSet.decisivePlayerId;
      isLoading = false;
    });
  }

  Future<void> _updateSet(MatchSet updated) async {
    matchSet = updated;
    await repo.updateMatchSet(matchSet);
    setState(() {});
  }

  void _increaseScore(int team) {
    _buttonController.forward(from: 0.88);

    if (team == 1) {
      _updateSet(matchSet.copyWith(team1Score: matchSet.team1Score + 1));
    } else {
      _updateSet(matchSet.copyWith(team2Score: matchSet.team2Score + 1));
    }
  }

  void _decreaseScore(int team) {
    _buttonController.forward(from: 0.88);

    if (team == 1 && matchSet.team1Score > 0) {
      _updateSet(matchSet.copyWith(team1Score: matchSet.team1Score - 1));
    } else if (team == 2 && matchSet.team2Score > 0) {
      _updateSet(matchSet.copyWith(team2Score: matchSet.team2Score - 1));
    }
  }

  Future<void> _showEditScoreDialog(int team) async {
    final textTheme = Theme.of(context).textTheme;
    final controller = TextEditingController(text: team == 1 ? matchSet.team1Score.toString() : matchSet.team2Score.toString());

    final newScore = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modificar puntaje"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: "Nuevo puntaje"),
          style: textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: textTheme.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: Text("Guardar", style: textTheme.bodyMedium),
          ),
        ],
      ),
    );

    if (newScore != null && newScore >= 0) {
      if (team == 1) {
        _updateSet(matchSet.copyWith(team1Score: newScore));
      } else {
        _updateSet(matchSet.copyWith(team2Score: newScore));
      }
    }
  }

  Future<void> _finishSet() async {
    final textTheme = Theme.of(context).textTheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar"),
        content: Text("¿Seguro que quieres finalizar este set?", style: textTheme.bodyLarge),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancelar", style: textTheme.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Sí, finalizar", style: textTheme.bodyMedium),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    int? winner;
    if (matchSet.team1Score > matchSet.team2Score) {
      winner = matchSet.team1Id;
    } else if (matchSet.team2Score > matchSet.team1Score) {
      winner = matchSet.team2Id;
    }

    final players = [...team1Players, ...team2Players];

    if (!mounted) return;
    final mvp = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Seleccionar MVP"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: players.map((p) => ListTile(title: Text(p.player?.name ?? "Jugador ${p.playerId}"), onTap: () => Navigator.pop(context, p.playerId))).toList(),
          ),
        ),
      ),
    );

    await _updateSet(matchSet.copyWith(finished: true, decisivePlayerId: mvp, winnerTeamId: winner));

    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          _teamsHeader(textTheme),
          const SizedBox(height: 10),
          _scoreRow(textTheme),
          if (!isLandscape) const SizedBox(height: 20),
          if (!isLandscape) _finishButton(textTheme),
          if (!isLandscape) const SizedBox(height: 20),
          if (!isLandscape) Expanded(child: _playersGrid(textTheme)),
        ],
      ),
    );
  }

  Widget _teamsHeader(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(matchSet.team1?.name ?? "Equipo 1", style: textTheme.titleLarge),
        Text(matchSet.team2?.name ?? "Equipo 2", style: textTheme.titleLarge),
      ],
    );
  }

  Widget _scoreRow(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _scoreColumn(textTheme, matchSet.team1Score, 1, true),
        Text(":", style: textTheme.titleLarge),
        _scoreColumn(textTheme, matchSet.team2Score, 2, false),
      ],
    );
  }

  Widget _finishButton(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.blue)),
          onPressed: matchSet.finished ? null : _finishSet,
          child: Text(matchSet.finished ? "Set Finalizado" : "Finalizar Set", style: textTheme.titleMedium),
        ),
      ],
    );
  }

  Widget _scoreColumn(TextTheme textTheme, int score, int team, bool isLeft) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final deviceHeight = MediaQuery.of(context).size.height;
    final textSize = (isLandscape ? deviceHeight * 0.25 : 20.0);
    final buttonSize = (isLandscape ? deviceHeight * 0.5 : 80.0);

    return Column(
      children: [
        if (isLandscape) SizedBox(height: deviceHeight * 0.1),
        Row(
          children: [
            if (isLeft) _smallBtn("-", () => _decreaseScore(team)),
            ScaleTransition(
              scale: _buttonScale,
              child: GestureDetector(
                onTap: () => _increaseScore(team),
                onLongPress: () => _showEditScoreDialog(team),
                child: ElevatedButton(
                  onPressed: () => _increaseScore(team),
                  style: ElevatedButton.styleFrom(minimumSize: Size(buttonSize, buttonSize), shape: const CircleBorder(), padding: EdgeInsets.zero),
                  child: Text("$score", style: textTheme.headlineMedium?.copyWith(fontSize: textSize)),
                ),
              ),
            ),
            if (!isLeft) _smallBtn("-", () => _decreaseScore(team)),
          ],
        ),
      ],
    );
  }

  Widget _smallBtn(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(minimumSize: const Size(32, 32), shape: const CircleBorder(), padding: EdgeInsets.zero),
        child: Text(label),
      ),
    );
  }

  Widget _playersGrid(TextTheme textTheme) {
    return Row(
      children: [
        Expanded(child: ListView(children: team1Players.map((p) => _playerCard(p, true, textTheme)).toList())),
        const SizedBox(width: 12),
        Expanded(child: ListView(children: team2Players.map((p) => _playerCard(p, false, textTheme)).toList())),
      ],
    );
  }

  Widget _playerCard(MatchTeamPlayer p, bool isTeam1, TextTheme textTheme) {
    final name = p.player?.name ?? "Jugador ${p.playerId}";
    final pos = p.position?.shortName;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          mainAxisAlignment: isTeam1 ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (isTeam1 && pos != null) _posBadge(pos),
            if (isTeam1) const SizedBox(width: 10),
            Expanded(
              child: Text(name, style: textTheme.bodyLarge, overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: isTeam1 ? TextAlign.left : TextAlign.right),
            ),
            if (!isTeam1) const SizedBox(width: 10),
            if (!isTeam1 && pos != null) _posBadge(pos),
          ],
        ),
      ),
    );
  }

  Widget _posBadge(String pos) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.blueGrey.shade300, borderRadius: BorderRadius.circular(6)),
      child: Text(
        pos,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
