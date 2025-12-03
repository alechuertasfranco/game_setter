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
    setState(() {
      courts = data;
      isLoading = false;
    });
  }

  void goToAddCourt() async {
    final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCourtPage()));

    if (created == true) {
      loadCourts();
    }
  }

  void goToEditCourt(Court c) async {
    final updated = await Navigator.pushNamed(context, '/editCourt', arguments: c);

    if (updated == true) {
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
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: courts.length,
                itemBuilder: (context, i) {
                  final c = courts[i];
                  return CourtCard(court: c).onCardAction(() {
                    loadCourts();
                  });
                },
              ),
            ),
    );
  }
}
