import 'package:flutter/material.dart';
import 'package:game_setter/features/matches/data/match_repository.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/presentation/widgets/match_card.dart';
import 'package:game_setter/features/matches/presentation/widgets/match_card_extension.dart';
import 'add_match_page.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  List<Match> matches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMatches();
  }

  Future<void> loadMatches() async {
    final data = await MatchRepository().getAllMatchesDetailed();
    setState(() {
      matches = data;
      isLoading = false;
    });
  }

  void goToAddMatch() async {
    final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMatchPage()));

    if (created == true) {
      loadMatches();
    }
  }

  void goToEditMatch(Match m) async {
    final updated = await Navigator.pushNamed(context, '/editMatch', arguments: m);

    if (updated == true) {
      loadMatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Partidos", style: textTheme.headlineSmall?.copyWith(color: Colors.white)),
        backgroundColor: Colors.blueGrey,
        elevation: 4,
      ),

      floatingActionButton: FloatingActionButton(onPressed: goToAddMatch, tooltip: 'Crear partido', shape: const CircleBorder(), child: const Icon(Icons.add)),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : matches.isEmpty
          ? Center(child: Text('No hay partidos aún', style: textTheme.bodyLarge))
          : SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: matches.length,
                itemBuilder: (context, i) {
                  final m = matches[i];
                  return MatchCard(match: m).onCardAction(() {
                    loadMatches();
                  });
                },
              ),
            ),
    );
  }
}
