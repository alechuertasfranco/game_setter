import 'package:flutter/material.dart';
import 'package:game_setter/features/courts/domain/entities/court.dart';
import 'package:game_setter/features/courts/data/court_repository.dart';
import 'package:game_setter/features/courts/presentation/widgets/court_form.dart';

class EditCourtPage extends StatefulWidget {
  final Court court;

  const EditCourtPage({super.key, required this.court});

  @override
  State<EditCourtPage> createState() => _EditCourtPageState();
}

class _EditCourtPageState extends State<EditCourtPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar cancha")),
      body: CourtForm(
        initialCourt: widget.court,
        onSave: (court) async {
          await CourtRepository().updateCourt(court);
        },
      ),
    );
  }
}
