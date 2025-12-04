import 'package:flutter/material.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/courts/domain/entities/court.dart';

class PlayersList extends StatelessWidget {
  final List<MatchPlayer> allPlayers;
  final List<MatchPlayer> selectedPlayers;
  final Court? matchCourt;
  final String type;
  final void Function(MatchPlayer) toggleSelection;

  const PlayersList({super.key, required this.allPlayers, required this.selectedPlayers, required this.toggleSelection, required this.type, this.matchCourt});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Si es Reserva, solo mostramos la cancha
    if (type == 'Reserva' && matchCourt != null) {
      return ListTile(
        leading: const Icon(Icons.location_on, size: 20),
        title: Text('Cancha: ${matchCourt!.name}', style: textTheme.bodyLarge),
      );
    }

    return allPlayers.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: allPlayers.length,
            itemBuilder: (context, index) {
              final p = allPlayers[index];
              final isSelected = selectedPlayers.contains(p);
              final phone = p.player?.phone;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text(p.player?.name ?? 'Player ${p.playerId}', style: textTheme.bodyLarge),
                  subtitle: phone != null ? Text(phone, style: textTheme.bodySmall) : null,
                  trailing: IconButton(
                    icon: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.green : Colors.grey, size: 20),
                    onPressed: () => toggleSelection(p),
                  ),
                  onTap: () => toggleSelection(p),
                ),
              );
            },
          );
  }
}
