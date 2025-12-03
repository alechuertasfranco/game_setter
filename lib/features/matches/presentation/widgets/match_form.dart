import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/sports/domain/entities/sport.dart';
import 'package:game_setter/features/courts/domain/entities/court.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';

import 'package:game_setter/features/sports/data/sport_repository.dart';
import 'package:game_setter/features/courts/data/court_repository.dart';
import 'package:game_setter/features/players/data/player_repository.dart';

import 'package:game_setter/features/matches/presentation/widgets/add_players_sheet.dart';

typedef OnSaveMatch = Future<void> Function(Match match);

class MatchForm extends StatefulWidget {
  final Match? initialMatch;
  final OnSaveMatch onSave;

  const MatchForm({super.key, this.initialMatch, required this.onSave});

  @override
  State<MatchForm> createState() => _MatchFormState();
}

class _MatchFormState extends State<MatchForm> {
  final SportRepository sportRepository = SportRepository();
  final CourtRepository courtRepository = CourtRepository();
  final PlayerRepository playerRepository = PlayerRepository();

  // Form controllers / state
  int? selectedSportId;
  List<Sport> sports = [];

  int? selectedCourtId;
  List<Court> courts = [];

  String? date; // YYYY-MM-DD
  String? time; // HH:mm

  // Available players filtered by sport
  List<Player> availablePlayers = [];

  // Players added to the match (keeps attended/paid flags)
  final List<MatchPlayer> matchPlayers = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  Future<void> _initForm() async {
    sports = await sportRepository.getSports();
    courts = await courtRepository.getAllCourts();

    if (widget.initialMatch != null) {
      final m = widget.initialMatch!;
      selectedSportId = m.sportId;
      selectedCourtId = m.courtId;
      date = m.date;
      time = m.time;

      // copy initial players if present
      matchPlayers.clear();
      matchPlayers.addAll(m.players);

      // load available players for the sport
      if (selectedSportId != null) {
        availablePlayers = await playerRepository.getPlayersBySport(selectedSportId!);
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _onSportChanged(int? sportId) async {
    if (sportId == null) return;
    // change sport => clear players selection by default
    setState(() {
      selectedSportId = sportId;
      selectedCourtId = null;
      matchPlayers.clear();
      availablePlayers = [];
      isLoading = true;
    });

    availablePlayers = await playerRepository.getPlayersBySport(sportId);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = date != null ? DateTime.tryParse(date!) ?? now : now;
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(now.year - 5), lastDate: DateTime(now.year + 5));
    if (picked != null) {
      setState(() {
        date = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    TimeOfDay initial = now;
    if (time != null) {
      final parts = time!.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? now.hour;
        final m = int.tryParse(parts[1]) ?? now.minute;
        initial = TimeOfDay(hour: h, minute: m);
      }
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        time = formatted;
      });
    }
  }

  void _showAddPlayersSheet() async {
    if (selectedSportId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleccione un deporte primero")));
      return;
    }
    await showAddPlayersSheet(context: context, sportId: selectedSportId!, playerRepository: playerRepository, matchPlayers: matchPlayers);
    setState(() {});
  }

  void _toggleAttended(MatchPlayer mp) {
    final idx = matchPlayers.indexWhere((e) => e.playerId == mp.playerId);
    if (idx == -1) return;
    final existing = matchPlayers[idx];
    matchPlayers[idx] = existing.copyWith(attended: !existing.attended);
    setState(() {});
  }

  void _togglePaid(MatchPlayer mp) {
    final idx = matchPlayers.indexWhere((e) => e.playerId == mp.playerId);
    if (idx == -1) return;
    final existing = matchPlayers[idx];
    matchPlayers[idx] = existing.copyWith(paid: !existing.paid);
    setState(() {});
  }

  Future<void> _removePlayer(MatchPlayer mp) async {
    matchPlayers.removeWhere((e) => e.playerId == mp.playerId);
    setState(() {});
  }

  Future<void> _save() async {
    if (selectedSportId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleccione un deporte")));
      return;
    }

    final id = widget.initialMatch?.id ?? 0;
    final match = Match(
      id: id,
      sportId: selectedSportId!,
      courtId: selectedCourtId,
      date: date,
      time: time,
      sportName: sports.firstWhere((s) => s.id == selectedSportId!).name,
      courtName: courts.firstWhere((c) => c.id == selectedCourtId, orElse: () => Court(id: 0, name: '', phone: null, location: null, hourlyRate: null)).name,
      players: List<MatchPlayer>.from(matchPlayers),
    );

    await widget.onSave(match);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sport selector
            DropdownButtonFormField<int?>(
              initialValue: selectedSportId,
              decoration: const InputDecoration(labelText: "Deporte"),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text("Seleccionar deporte")),
                ...sports.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
              ],
              onChanged: (v) async => await _onSportChanged(v),
            ),

            const SizedBox(height: 12),

            // Date & Time row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: date ?? ''),
                    decoration: const InputDecoration(labelText: "Fecha"),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(text: time ?? ''),
                    decoration: const InputDecoration(labelText: "Hora"),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Court selector
            DropdownButtonFormField<int?>(
              initialValue: selectedCourtId,
              decoration: const InputDecoration(labelText: "Cancha"),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text("Seleccionar cancha")),
                ...courts.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) => setState(() => selectedCourtId = v),
            ),

            const SizedBox(height: 16),

            // Add players button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(icon: const Icon(Icons.person_add), label: const Text("Añadir jugadores"), onPressed: _showAddPlayersSheet),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Players list
            Expanded(
              child: matchPlayers.isEmpty
                  ? const Center(child: Text("No hay jugadores agregados"))
                  : ListView.builder(
                      itemCount: matchPlayers.length,
                      itemBuilder: (context, i) {
                        final mp = matchPlayers[i];

                        // try to find player details in availablePlayers or show id
                        final player = availablePlayers.firstWhere(
                          (p) => p.id == mp.playerId,
                          orElse: () => Player(id: mp.playerId, name: mp.playerId, phone: null),
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            title: Text(player.name, style: textTheme.bodyLarge),
                            subtitle: player.phone != null ? Text(player.phone!, style: textTheme.bodyMedium) : null,
                            leading: Container(
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withAlpha(12)),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.person, color: Colors.blue, size: 28),
                            ),

                            // Attendance & Paid icons
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Attended toggle (green)
                                IconButton(
                                  icon: Icon(Icons.check_circle, color: mp.attended ? Colors.green : Colors.grey),
                                  onPressed: () => _toggleAttended(mp),
                                ),
                                // Paid toggle (blue)
                                IconButton(
                                  icon: Icon(Icons.attach_money, color: mp.paid ? Colors.blue : Colors.grey),
                                  onPressed: () => _togglePaid(mp),
                                ),
                                // Remove player
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _removePlayer(mp),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _save, child: Text(widget.initialMatch == null ? "Guardar partido" : "Guardar cambios")),
            ),
          ],
        ),
      ),
    );
  }
}
