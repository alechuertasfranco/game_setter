import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:game_setter/features/players/data/player_repository.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/players/presentation/widgets/player_form.dart';
import 'package:game_setter/features/sports/domain/entities/sport.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class AddPlayerPage extends StatefulWidget {
  const AddPlayerPage({super.key});

  @override
  State<AddPlayerPage> createState() => _AddPlayerPageState();
}

class _AddPlayerPageState extends State<AddPlayerPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  // Catálogo
  List<Sport> sports = [];

  // Control para añadir nuevos deportes seleccionados por el usuario
  int? sportToAddId;
  Map<int, List<Position>> positionsBySport = {}; // cache de posiciones por deporte

  // Deportes seleccionados por el usuario (lista de sportId)
  final List<int> selectedSports = [];

  // Para cada sportId guardamos el set de positionIds seleccionados
  final Map<int, Set<int>> selectedPositionsBySport = {};

  @override
  void initState() {
    super.initState();
    loadSports();
  }

  Future<void> loadSports() async {
    sports = await PlayerRepository().getSports();
    setState(() {});
  }

  // Carga posiciones y cachea
  Future<void> _ensurePositionsLoaded(int sportId) async {
    if (!positionsBySport.containsKey(sportId)) {
      final positions = await PlayerRepository().getPositionsBySport(sportId);
      positionsBySport[sportId] = positions;
    }
  }

  Future<void> pickContact() async {
    if (!await FlutterContacts.requestPermission()) return;

    final contact = await FlutterContacts.openExternalPick();
    if (contact == null) return;

    final full = await FlutterContacts.getContact(contact.id);
    nameCtrl.text = full?.displayName ?? "";

    if (full != null && full.phones.isNotEmpty) {
      phoneCtrl.text = full.phones.first.number;
    }
  }

  // Añadir deporte (si no está ya)
  Future<void> addSelectedSport() async {
    final id = sportToAddId;
    if (id == null) return;
    if (selectedSports.contains(id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El deporte ya fue agregado')));
      return;
    }

    await _ensurePositionsLoaded(id); // cache positions
    selectedSports.add(id);
    selectedPositionsBySport[id] = <int>{}; // inicialmente vacío (sin posiciones)
    setState(() {});
  }

  // Quitar deporte, limpiando selecciones
  void removeSelectedSport(int sportId) {
    selectedSports.remove(sportId);
    selectedPositionsBySport.remove(sportId);
    setState(() {});
  }

  // Toggle posición en un deporte (checkbox/chip)
  void togglePosition(int sportId, int positionId) {
    final set = selectedPositionsBySport[sportId] ?? <int>{};
    if (set.contains(positionId)) {
      set.remove(positionId);
    } else {
      set.add(positionId);
    }
    selectedPositionsBySport[sportId] = set;
    setState(() {});
  }

  Future<void> savePlayer() async {
    if (nameCtrl.text.trim().isEmpty) return;

    final p = Player(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim());

    // --- ASYNC WORK ---
    await PlayerRepository().insertPlayerOnly(p);

    for (final sportId in selectedSports) {
      final positions = selectedPositionsBySport[sportId];

      if (positions == null || positions.isEmpty) {
        await PlayerRepository().assignSportToPlayer(p.id, sportId, null);
      } else {
        for (final posId in positions) {
          await PlayerRepository().assignSportToPlayer(p.id, sportId, posId);
        }
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agregar jugador")),
      body: PlayerForm(
        onSave: (player, sports, positionsBySport) async {
          await PlayerRepository().insertPlayerOnly(player);
          for (final sportId in sports) {
            final posSet = positionsBySport[sportId];
            if (posSet == null || posSet.isEmpty) {
              await PlayerRepository().assignSportToPlayer(player.id, sportId, null);
            } else {
              for (final posId in posSet) {
                await PlayerRepository().assignSportToPlayer(player.id, sportId, posId);
              }
            }
          }
        },
      ),
    );
  }
}
