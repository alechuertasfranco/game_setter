import 'package:flutter/material.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/players/data/player_repository.dart';
import 'package:game_setter/features/players/presentation/widgets/player_form.dart';
import 'package:game_setter/features/sports/domain/entities/sport.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class EditPlayerPage extends StatefulWidget {
  final Player player;

  const EditPlayerPage({super.key, required this.player});

  @override
  State<EditPlayerPage> createState() => _EditPlayerPageState();
}

class _EditPlayerPageState extends State<EditPlayerPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  // Catálogo general:
  List<Sport> sports = [];

  // Cache de posiciones por deporte
  Map<int, List<Position>> positionsBySport = {};

  // Deportes seleccionados
  final List<int> selectedSports = [];

  // Para cada sport ID: posiciones seleccionadas
  final Map<int, Set<int>> selectedPositionsBySport = {};

  // Para el selector de deportes (añadir)
  int? sportToAddId;

  @override
  void initState() {
    super.initState();
    nameCtrl.text = widget.player.name;
    phoneCtrl.text = widget.player.phone ?? "";
    loadInitial();
  }

  Future<void> loadInitial() async {
    sports = await PlayerRepository().getSports();

    // Cargar deportes/posiciones actuales del jugador
    final playerSports = await PlayerRepository().getPlayerSports(widget.player.id);

    for (final row in playerSports) {
      final sportId = row['sport_id'] as int;
      final posId = row['position_id'] as int?;

      if (!selectedSports.contains(sportId)) {
        selectedSports.add(sportId);
        selectedPositionsBySport[sportId] = <int>{};
      }

      if (posId != null) {
        selectedPositionsBySport[sportId]!.add(posId);
      }

      // Cache posiciones
      if (!positionsBySport.containsKey(sportId)) {
        final posList = await PlayerRepository().getPositionsBySport(sportId);
        positionsBySport[sportId] = posList;
      }
    }

    setState(() {});
  }

  Future<void> _ensurePositionsLoaded(int sportId) async {
    if (!positionsBySport.containsKey(sportId)) {
      final posList = await PlayerRepository().getPositionsBySport(sportId);
      positionsBySport[sportId] = posList;
    }
  }

  Future<void> addSelectedSport() async {
    final id = sportToAddId;
    if (id == null) return;

    if (selectedSports.contains(id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El deporte ya está agregado")));
      return;
    }

    await _ensurePositionsLoaded(id);

    selectedSports.add(id);
    selectedPositionsBySport[id] = <int>{};

    setState(() {});
  }

  void removeSelectedSport(int sportId) {
    selectedSports.remove(sportId);
    selectedPositionsBySport.remove(sportId);
    setState(() {});
  }

  void togglePosition(int sportId, int posId) {
    final set = selectedPositionsBySport[sportId] ?? <int>{};

    if (set.contains(posId)) {
      set.remove(posId);
    } else {
      set.add(posId);
    }

    selectedPositionsBySport[sportId] = set;
    setState(() {});
  }

  Future<void> savePlayer() async {
    if (nameCtrl.text.trim().isEmpty) return;

    // Actualizar datos del jugador
    final p = Player(id: widget.player.id, name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim());

    await PlayerRepository().updatePlayerOnly(p);
    await PlayerRepository().clearPlayerSports(widget.player.id);

    // Guardar deportes + posiciones
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
      appBar: AppBar(title: const Text("Editar jugador")),
      body: PlayerForm(
        initialPlayer: widget.player,
        onSave: (p, sports, positionsBySport) async {
          await PlayerRepository().updatePlayerOnly(p);
          await PlayerRepository().clearPlayerSports(p.id);

          for (final sportId in sports) {
            final posSet = positionsBySport[sportId];
            if (posSet == null || posSet.isEmpty) {
              await PlayerRepository().assignSportToPlayer(p.id, sportId, null);
            } else {
              for (final posId in posSet) {
                await PlayerRepository().assignSportToPlayer(p.id, sportId, posId);
              }
            }
          }
        },
      ),
    );
  }
}
