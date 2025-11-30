import 'package:flutter/material.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/players/data/player_repository.dart';
import 'package:game_setter/features/players/presentation/widgets/player_card.dart';
import 'package:game_setter/features/players/presentation/widgets/player_card_extension.dart';
import 'add_player_page.dart';

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  List<Player> players = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPlayers();
  }

  Future<void> loadPlayers() async {
    final data = await PlayerRepository().getAllPlayers();
    setState(() {
      players = data;
      isLoading = false;
    });
  }

  void goToAddPlayer() async {
    final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPlayerPage()));

    if (created == true) {
      loadPlayers();
    }
  }

  void goToEditPlayer(Player p) async {
    final updated = await Navigator.pushNamed(context, '/editPlayer', arguments: p);

    if (updated == true) {
      loadPlayers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("Jugadores", style: textTheme.headlineSmall),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        floatingActionButton: FloatingActionButton(onPressed: goToAddPlayer, child: const Icon(Icons.add)),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : players.isEmpty
            ? Center(child: Text('No hay jugadores aún', style: textTheme.bodyLarge))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: players.length,
                itemBuilder: (context, i) {
                  final p = players[i];
                  return PlayerCard(player: p).onCardAction(() {
                    loadPlayers();
                  });
                },
              ),
      ),
    );
  }
}
