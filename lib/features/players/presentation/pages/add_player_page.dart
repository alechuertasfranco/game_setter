import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:game_setter/features/players/data/player_repository.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            const SizedBox(height: 12),

            // Teléfono
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: "Teléfono"),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 12),

            // Selector para elegir qué deporte agregar
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

            const SizedBox(height: 12),

            // Lista de deportes que el usuario ha añadido
            Expanded(
              child: selectedSports.isEmpty
                  ? const Center(child: Text('No hay deportes agregados'))
                  : ListView(
                      children: selectedSports.map((sportId) {
                        final sport = sports.firstWhere((s) => s.id == sportId);
                        final positions = positionsBySport[sportId] ?? [];
                        final selectedSet = selectedPositionsBySport[sportId] ?? <int>{};

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ExpansionTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(sport.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(icon: const Icon(Icons.delete_forever), onPressed: () => removeSelectedSport(sportId)),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Posiciones (elige una o varias). Si no eliges ninguna, se guardará sin posición."),
                                    const SizedBox(height: 8),
                                    // Mostrar positions como chips toggles
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: positions.map((pos) {
                                        final isSelected = selectedSet.contains(pos.id);
                                        return FilterChip(label: Text("${pos.name} (${pos.shortName})"), selected: isSelected, onSelected: (_) => togglePosition(sportId, pos.id));
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 12),

            // Importar contacto
            ElevatedButton.icon(onPressed: pickContact, icon: const Icon(Icons.contacts), label: const Text("Importar desde contactos")),

            const SizedBox(height: 12),

            // Guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: savePlayer, child: const Text("Guardar")),
            ),
          ],
        ),
      ),
    );
  }
}
