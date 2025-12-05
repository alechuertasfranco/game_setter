import 'package:flutter/material.dart';
import 'package:game_setter/features/match_sets/data/match_set_repository.dart';
import 'package:game_setter/features/match_sets/presentation/widgets/match_set_form.dart';

class MatchSetPage extends StatefulWidget {
  final int matchId;
  final int team1Id;
  final int team2Id;
  final int? setId;

  const MatchSetPage({super.key, required this.matchId, required this.team1Id, required this.team2Id, this.setId});

  @override
  State<MatchSetPage> createState() => _MatchSetPageState();
}

class _MatchSetPageState extends State<MatchSetPage> {
  late int selectedSetId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initSelectedSet();
  }

  Future<void> _initSelectedSet() async {
    setState(() => isLoading = true);
    selectedSetId = widget.setId ?? await MatchSetRepository().initMatchSet(widget.matchId, widget.team1Id, widget.team2Id);
    setState(() => isLoading = false);
  }

  void _onSave() {
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: isLandscape
          ? null
          : AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text('Periodo', style: textTheme.headlineSmall?.copyWith(color: Colors.white)),
              backgroundColor: Colors.blueGrey,
              elevation: 4,
            ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : MatchSetForm(matchSetId: selectedSetId, onSave: _onSave),
    );
  }
}
