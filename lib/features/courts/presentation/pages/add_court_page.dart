import 'package:flutter/material.dart';
import 'package:game_setter/features/courts/data/court_repository.dart';
import 'package:game_setter/features/courts/presentation/widgets/court_form.dart';

class AddCourtPage extends StatefulWidget {
  const AddCourtPage({super.key});

  @override
  State<AddCourtPage> createState() => _AddCourtPageState();
}

class _AddCourtPageState extends State<AddCourtPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agregar cancha")),
      body: CourtForm(
        onSave: (court) async {
          await CourtRepository().insertCourt(court);
        },
      ),
    );
  }
}
