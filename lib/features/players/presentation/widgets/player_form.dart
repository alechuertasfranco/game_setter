import 'package:flutter/material.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/players/data/player_repository.dart';
import 'package:game_setter/features/sports/domain/entities/sport.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

typedef OnSavePlayer = Future<void> Function(Player player, List<int> sportIds, Map<int, Set<int>> positions);

class PlayerForm extends StatefulWidget {
  final Player? initialPlayer;
  final OnSavePlayer onSave;

  const PlayerForm({super.key, this.initialPlayer, required this.onSave});

  @override
  State<PlayerForm> createState() => _PlayerFormState();
}

class _PlayerFormState extends State<PlayerForm> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  List<Sport> sports = [];
  Map<int, List<Position>> positionsBySport = {};

  int? sportToAddId;
  int? expandedSportId;
  final List<int> selectedSports = [];
  final Map<int, Set<int>> selectedPositionsBySport = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialPlayer != null) {
      nameCtrl.text = widget.initialPlayer!.name;
      phoneCtrl.text = widget.initialPlayer!.phone ?? "";
    }
    _loadSportsAndSelections();
  }

  Future<void> _loadSportsAndSelections() async {
    sports = await PlayerRepository().getSports();
    if (widget.initialPlayer != null) {
      final playerSports = await PlayerRepository().getPlayerSports(widget.initialPlayer!.id);
      for (final row in playerSports) {
        final sportId = row['sport_id'] as int;
        final posId = row['position_id'] as int?;
        if (!selectedSports.contains(sportId)) selectedSports.add(sportId);
        selectedPositionsBySport[sportId] ??= <int>{};
        if (posId != null) selectedPositionsBySport[sportId]!.add(posId);

        if (!positionsBySport.containsKey(sportId)) {
          positionsBySport[sportId] = await PlayerRepository().getPositionsBySport(sportId);
        }
      }
    }
    setState(() {});
  }

  Future<void> _ensurePositionsLoaded(int sportId) async {
    if (!positionsBySport.containsKey(sportId)) {
      positionsBySport[sportId] = await PlayerRepository().getPositionsBySport(sportId);
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

    setState(() {
      sportToAddId = null;
      expandedSportId = id;
    });
  }

  void removeSelectedSport(int sportId) {
    selectedSports.remove(sportId);
    selectedPositionsBySport.remove(sportId);
    setState(() {});
  }

  void toggleExpandedSport(int sportId) {
    final isExpanded = expandedSportId == sportId;

    setState(() {
      expandedSportId = isExpanded ? null : sportId;
    });
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

  Future<void> save() async {
    if (nameCtrl.text.trim().isEmpty) return;
    final player =
        widget.initialPlayer ??
        Player(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim());

    await widget.onSave(player, selectedSports, selectedPositionsBySport);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: "Teléfono"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: sportToAddId,
                    decoration: const InputDecoration(labelText: "Agregar deporte"),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text("Seleccionar deporte")),
                      ...sports.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) => setState(() => sportToAddId = v),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: addSelectedSport, child: const Text("Añadir")),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: selectedSports.isEmpty
                  ? const Center(child: Text("No hay deportes agregados"))
                  : ListView(
                      children: selectedSports.map((sportId) {
                        final sport = sports.firstWhere((s) => s.id == sportId);
                        final positions = positionsBySport[sportId] ?? [];
                        final selectedSet = selectedPositionsBySport[sportId] ?? <int>{};
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ExpansionTile(
                            key: Key('$sportId-${expandedSportId == sportId}'),
                            initiallyExpanded: expandedSportId == sportId,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                expandedSportId = expanded ? sportId : null;
                              });
                            },
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [Text(sport.name, style: textTheme.titleMedium)],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Posiciones"),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: positions.map((pos) {
                                        final isSelected = selectedSet.contains(pos.id);
                                        return FilterChip(
                                          label: Text("${pos.name} (${pos.shortName})", style: const TextStyle(fontSize: 12)),
                                          selected: isSelected,
                                          onSelected: (_) => togglePosition(sportId, pos.id),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.delete, size: 18),
                                          label: const Text("Eliminar", style: TextStyle(fontSize: 13)),
                                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14), visualDensity: VisualDensity.compact),
                                          onPressed: () => removeSelectedSport(sportId),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.save, size: 18),
                                          label: const Text("Guardar", style: TextStyle(fontSize: 13)),
                                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14), visualDensity: VisualDensity.compact),
                                          // este botón ahora solo colapsa el tile (no guarda todo)
                                          onPressed: () => toggleExpandedSport(sportId),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: save, child: Text(widget.initialPlayer == null ? "Guardar" : "Guardar cambios")),
            ),
          ],
        ),
      ),
    );
  }
}
