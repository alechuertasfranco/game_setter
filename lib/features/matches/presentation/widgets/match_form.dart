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

  int? selectedSportId;
  int? selectedCourtId;
  String? date;
  String? time;

  List<Sport> sports = [];
  List<Court> courts = [];
  List<Player> availablePlayers = [];
  final List<MatchPlayer> matchPlayers = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  /// ----------------------------
  /// INIT
  /// ----------------------------
  Future<void> _initForm() async {
    sports = await sportRepository.getSports();
    courts = await courtRepository.getAllCourts();

    final initial = widget.initialMatch;
    if (initial != null) {
      selectedSportId = initial.sportId;
      selectedCourtId = initial.courtId;
      date = initial.date;
      time = initial.time;
      matchPlayers.addAll(initial.players);

      if (selectedSportId != null) {
        availablePlayers = await playerRepository.getPlayersBySport(selectedSportId!);
      }
    }

    setState(() => isLoading = false);
  }

  /// ----------------------------
  /// HELPERS
  /// ----------------------------
  Future<void> _onSportChanged(int? id) async {
    if (id == null) return;

    setState(() {
      selectedSportId = id;
      selectedCourtId = null;
      matchPlayers.clear();
      availablePlayers = [];
      isLoading = true;
    });

    availablePlayers = await playerRepository.getPlayersBySport(id);
    setState(() => isLoading = false);
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
      if (parts.length == 2) {
        initial = TimeOfDay(hour: int.tryParse(parts[0]) ?? now.hour, minute: int.tryParse(parts[1]) ?? now.minute);
      }
    }

    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked != null) {
      setState(() => time = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}");
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

  void _toggleAttended(MatchPlayer mp) => _updatePlayer(mp, attended: !mp.attended);
  void _togglePaid(MatchPlayer mp) => _updatePlayer(mp, paid: !mp.paid);

  void _updatePlayer(MatchPlayer mp, {bool? attended, bool? paid}) {
    final i = matchPlayers.indexWhere((e) => e.playerId == mp.playerId);
    if (i == -1) return;

    matchPlayers[i] = matchPlayers[i].copyWith(attended: attended ?? matchPlayers[i].attended, paid: paid ?? matchPlayers[i].paid);

    setState(() {});
  }

  Future<void> _removePlayer(MatchPlayer mp) async {
    matchPlayers.removeWhere((e) => e.playerId == mp.playerId);
    setState(() {});
  }

  /// ----------------------------
  /// SAVE MATCH
  /// ----------------------------
  Future<void> _save() async {
    if (selectedSportId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleccione un deporte")));
      return;
    }

    final match = Match(
      id: widget.initialMatch?.id ?? 0,
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

  /// ----------------------------
  /// UI BUILD HELPERS
  /// ----------------------------
  Widget _buildDropdown<T>({required T? value, required String label, required List<DropdownMenuItem<T>> items, required Function(T?) onChanged}) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({required String label, required String? value, required VoidCallback onTap}) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: value ?? ''),
      decoration: InputDecoration(labelText: label),
      onTap: onTap,
    );
  }

  Widget _buildSwipeBackground(Color color, Alignment align, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: color,
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Future<bool?> _handleDismiss(MatchPlayer mp, Player player, TextTheme textTheme, DismissDirection direction) async {
    if (direction == DismissDirection.startToEnd) {
      _toggleAttended(mp);
      return false;
    }

    if (direction == DismissDirection.endToStart) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Quitar jugador", style: textTheme.titleMedium),
          content: Text("¿Seguro que deseas quitar a ${player.name} del partido?", style: textTheme.bodyMedium),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Quitar", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );

      if (confirm == true) _removePlayer(mp);
      return confirm;
    }

    return false;
  }

  Widget _buildPlayerTile(MatchPlayer mp, Player p, TextTheme textTheme) {
    return Card(
      margin: const EdgeInsets.all(0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withAlpha(12)),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.person, color: Colors.blue, size: 28),
        ),
        title: Text(p.name, style: textTheme.bodyLarge),
        subtitle: p.phone != null ? Text(p.phone!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check_circle, color: mp.attended ? Colors.green : Colors.grey),
              onPressed: () => _toggleAttended(mp),
            ),
            IconButton(
              icon: Icon(Icons.attach_money, color: mp.paid ? Colors.blue : Colors.grey),
              onPressed: () => _togglePaid(mp),
            ),
          ],
        ),
      ),
    );
  }

  /// ----------------------------
  /// BUILD
  /// ----------------------------
  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown<int?>(
              value: selectedSportId,
              label: "Deporte",
              items: [
                DropdownMenuItem(value: null, child: Text("Seleccionar deporte", style: textTheme.bodyLarge)),
                ...sports.map(
                  (s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name, style: textTheme.bodyLarge),
                  ),
                ),
              ],
              onChanged: (v) async => await _onSportChanged(v),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDateField(label: "Fecha", value: date, onTap: _pickDate),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(label: "Hora", value: time, onTap: _pickTime),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _buildDropdown<int?>(
              value: selectedCourtId,
              label: "Cancha",
              items: [
                DropdownMenuItem(value: null, child: Text("Seleccionar cancha", style: textTheme.bodyLarge)),
                ...courts.map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name, style: textTheme.bodyLarge),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => selectedCourtId = v),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_add, color: Color(0xFF1565C0)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.blue.shade800)),
                    label: Text("Añadir jugadores", style: textTheme.titleMedium?.copyWith(color: Colors.blue.shade800)),
                    onPressed: _showAddPlayersSheet,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: matchPlayers.isEmpty
                  ? const Center(child: Text("No hay jugadores agregados"))
                  : ListView.builder(
                      itemCount: matchPlayers.length,
                      itemBuilder: (_, i) {
                        final mp = matchPlayers[i];
                        final p = availablePlayers.firstWhere((x) => x.id == mp.playerId);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Dismissible(
                            key: ValueKey("mp_${mp.playerId}"),
                            direction: DismissDirection.horizontal,
                            confirmDismiss: (dir) => _handleDismiss(mp, p, textTheme, dir),
                            background: _buildSwipeBackground(Colors.blue, Alignment.centerLeft, Icons.check_circle),
                            secondaryBackground: _buildSwipeBackground(Colors.redAccent, Alignment.centerRight, Icons.delete),
                            child: _buildPlayerTile(mp, p, textTheme),
                          ),
                        );
                      },
                    ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.blue.shade800)),
                child: Text(widget.initialMatch == null ? "Guardar partido" : "Guardar cambios", style: textTheme.titleMedium?.copyWith(color: Colors.blue.shade800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
