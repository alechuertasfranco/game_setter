import 'package:flutter/material.dart';
import 'package:game_setter/features/courts/domain/entities/court.dart';
import 'package:url_launcher/url_launcher.dart';

typedef OnSaveCourt = Future<void> Function(Court court);

class CourtForm extends StatefulWidget {
  final Court? initialCourt;
  final OnSaveCourt onSave;

  const CourtForm({super.key, this.initialCourt, required this.onSave});

  @override
  State<CourtForm> createState() => _CourtFormState();
}

class _CourtFormState extends State<CourtForm> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController locationCtrl = TextEditingController();
  final TextEditingController hourlyRateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCourt != null) {
      nameCtrl.text = widget.initialCourt!.name;
      phoneCtrl.text = widget.initialCourt!.phone ?? "";
      locationCtrl.text = widget.initialCourt!.location ?? "";
      hourlyRateCtrl.text = widget.initialCourt!.hourlyRate?.toString() ?? "";
    }
  }

  Future<void> pickLocation() async {
    const url = "https://www.google.com/maps/search/?api=1&query=";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copia la dirección desde Google Maps y pégala aquí.")));
  }

  Future<void> save() async {
    if (nameCtrl.text.trim().isEmpty) return;

    final court = Court(
      id: widget.initialCourt?.id,
      name: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
      hourlyRate: hourlyRateCtrl.text.trim().isEmpty ? null : double.tryParse(hourlyRateCtrl.text.trim()),
    );

    await widget.onSave(court);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre (obligatorio)
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre *"),
            ),
            const SizedBox(height: 12),

            // Teléfono
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: "Teléfono"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            // Dirección
            TextField(
              controller: locationCtrl,
              decoration: InputDecoration(
                labelText: "Dirección (Google Maps)",
                suffixIcon: IconButton(icon: const Icon(Icons.map), onPressed: pickLocation),
              ),
            ),
            const SizedBox(height: 12),

            // Tarifa por hora
            TextField(
              controller: hourlyRateCtrl,
              decoration: const InputDecoration(labelText: "Tarifa por hora (S/.)"),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: save, child: Text(widget.initialCourt == null ? "Guardar" : "Guardar cambios")),
            ),
          ],
        ),
      ),
    );
  }
}
