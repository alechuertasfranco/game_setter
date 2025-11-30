import 'package:flutter/material.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/players/data/player_repository.dart';
import 'package:game_setter/features/players/presentation/widgets/player_card.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jugadores")),
      floatingActionButton: FloatingActionButton(onPressed: goToAddPlayer, child: const Icon(Icons.add)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, i) {
                final p = players[i];
                return PlayerCard(player: p);
              },
            ),
    );
  }
}
