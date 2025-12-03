import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:game_setter/features/courts/domain/entities/court.dart';
import 'package:game_setter/features/courts/data/court_repository.dart';
import 'package:game_setter/features/courts/presentation/widgets/court_card.dart';
import 'package:game_setter/features/courts/presentation/widgets/court_card_extension.dart';
import 'package:game_setter/shared/widgets/import_contacts_sheet.dart';
import 'package:game_setter/features/courts/presentation/pages/add_court_page.dart';

class CourtsPage extends StatefulWidget {
  const CourtsPage({super.key});

  @override
  State<CourtsPage> createState() => _CourtsPageState();
}

class _CourtsPageState extends State<CourtsPage> {
  List<Court> courts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCourts();
  }

  Future<void> loadCourts() async {
    final data = await CourtRepository().getAllCourts();
    for (var court in data) {
      court.subtitle = court.phone ?? "Sin teléfono";
      if (court.location != null && court.location!.trim().isNotEmpty) {
        court.subtitle = court.location!;
      }
    }

    setState(() {
      courts = data;
      isLoading = false;
    });
  }

  void handleReorderCourts(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final movedCourt = courts.removeAt(oldIndex);
    courts.insert(newIndex, movedCourt);
    setState(() {});

    for (int i = 0; i < courts.length; i++) {
      if (courts[i].id == null) continue;
      await CourtRepository().updateCourtPosition(courts[i].id!, i);
      courts[i] = courts[i].copyWith(position: i);
    }
  }

  void goToAddCourt() async {
    final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCourtPage()));

    if (created == true) {
      loadCourts();
    }
  }

  void importContact() async {
    final contacts = await showImportContactsSheet(context);
    if (contacts != null && contacts.isNotEmpty) {
      for (var c in contacts) {
        final newCourt = Court(name: c['name']!, phone: c['phone']);
        await CourtRepository().insertCourt(newCourt);
      }
      loadCourts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${contacts.length} canchas importadas")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Canchas", style: textTheme.headlineSmall?.copyWith(color: Colors.white)),
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
          SpeedDialChild(child: const Icon(Icons.person_add, size: 20), label: 'Agregar cancha', labelStyle: textTheme.bodySmall, onTap: goToAddCourt, shape: const CircleBorder()),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : courts.isEmpty
          ? Center(child: Text('No hay canchas aún', style: textTheme.bodyLarge))
          : SafeArea(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(12).copyWith(bottom: 48),
                itemCount: courts.length,
                onReorder: handleReorderCourts,
                itemBuilder: (context, i) {
                  final c = courts[i];
                  return CourtCard(court: c).onCardAction(key: ValueKey(c.id), fn: loadCourts);
                },
              ),
            ),
    );
  }
}
