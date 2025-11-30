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

  List<Sport> sports = [];
  List<Position> positions = [];

  int? selectedSportId;
  int? selectedPositionId;

  @override
  void initState() {
    super.initState();
    loadSports();
  }

  Future<void> loadSports() async {
    sports = await PlayerRepository().getSports();
    setState(() {});
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

  Future<void> savePlayer() async {
    if (nameCtrl.text.trim().isEmpty) return;

    final p = Player(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim());

    // Guardar el jugador SIEMPRE
    await PlayerRepository().insertPlayerOnly(p);

    // Guardar deporte/posición SOLO si seleccionó un deporte
    if (selectedSportId != null) {
      await PlayerRepository().assignSportToPlayer(p.id, selectedSportId!, selectedPositionId);
    }

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

            // Importar contacto
            ElevatedButton.icon(onPressed: pickContact, icon: const Icon(Icons.contacts), label: const Text("Importar desde contactos")),

            const SizedBox(height: 20),

            // -------------------------
            // Seleccionar deporte
            // -------------------------
            DropdownButtonFormField<int>(
              initialValue: selectedSportId,
              decoration: const InputDecoration(labelText: "Deporte (opcional)"),
              items: [
                const DropdownMenuItem(value: null, child: Text("Ninguno")),
                ...sports.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
              ],
              onChanged: (value) async {
                selectedSportId = value;
                selectedPositionId = null;

                // Si seleccionó un deporte → cargar posiciones
                if (value != null) {
                  positions = await PlayerRepository().getPositionsBySport(value);
                } else {
                  positions = [];
                }

                setState(() {});
              },
            ),

            const SizedBox(height: 12),

            // -------------------------
            // Seleccionar posición
            // -------------------------
            if (selectedSportId != null)
              DropdownButtonFormField<int>(
                initialValue: selectedPositionId,
                decoration: const InputDecoration(labelText: "Posición (opcional)"),
                items: [
                  const DropdownMenuItem(value: null, child: Text("Sin posición")),
                  ...positions.map((p) => DropdownMenuItem(value: p.id, child: Text("${p.name} (${p.shortName})"))),
                ],
                onChanged: (value) {
                  selectedPositionId = value;
                  setState(() {});
                },
              ),

            const Spacer(),

            ElevatedButton(onPressed: savePlayer, child: const Text("Guardar")),
          ],
        ),
      ),
    );
  }
}
