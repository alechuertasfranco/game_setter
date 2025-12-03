import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/players/data/player_repository.dart';
import 'package:game_setter/shared/widgets/import_contacts_sheet.dart';
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

  void importContact() async {
    final contacts = await showImportContactsSheet(context);
    if (contacts != null && contacts.isNotEmpty) {
      for (var c in contacts) {
        final newPlayer = Player(id: DateTime.now().millisecondsSinceEpoch.toString(), name: c['name']!, phone: c['phone']);
        await PlayerRepository().insertPlayerOnly(newPlayer);
      }
      loadPlayers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${contacts.length} contactos importados")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Jugadores", style: textTheme.headlineSmall?.copyWith(color: Colors.white)),
        backgroundColor: Colors.blueGrey,
        elevation: 4,
      ),

      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        overlayOpacity: 0.5,
        spacing: 10,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.contacts, size: 20),
            label: 'Importar contacto',
            labelStyle: textTheme.bodySmall,
            onTap: importContact,
            shape: const CircleBorder(),
          ),
          SpeedDialChild(
            child: const Icon(Icons.person_add, size: 20),
            label: 'Agregar jugador',
            labelStyle: textTheme.bodySmall,
            onTap: goToAddPlayer,
            shape: const CircleBorder(),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : players.isEmpty
          ? Center(child: Text('No hay jugadores aún', style: textTheme.bodyLarge))
          : SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.all(12).copyWith(bottom: 48),
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
