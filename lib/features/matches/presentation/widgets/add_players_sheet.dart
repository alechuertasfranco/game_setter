// lib/features/matches/presentation/widgets/add_players_sheet.dart
import 'package:flutter/material.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/players/data/player_repository.dart';

/// Muestra un BottomSheet para agregar jugadores a un partido.
/// [sportId] indica el deporte seleccionado.
/// [matchPlayers] contiene los jugadores ya agregados (para deshabilitar duplicados).
/// Devuelve true si hubo cambios.
Future<void> showAddPlayersSheet({required BuildContext context, required int sportId, required PlayerRepository playerRepository, required List<MatchPlayer> matchPlayers}) async {
  List<Player> availablePlayers = [];
  List<Player> filteredPlayers = [];
  bool isLoading = true;

  // Cargar jugadores disponibles
  try {
    availablePlayers = await playerRepository.getPlayersBySport(sportId);
    filteredPlayers = List.from(availablePlayers);
  } catch (_) {
    availablePlayers = [];
    filteredPlayers = [];
  }
  isLoading = false;

  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, modalSetState) {
          void filterPlayers(String query) {
            final lowerQuery = query.toLowerCase();
            modalSetState(() {
              filteredPlayers = availablePlayers.where((p) => p.name.toLowerCase().contains(lowerQuery)).toList();
            });
          }

          void addPlayer(Player p) {
            matchPlayers.add(MatchPlayer(id: 0, matchId: 0, playerId: p.id, attended: false, paid: false));
            modalSetState(() {});
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${p.name} agregado"), duration: const Duration(milliseconds: 500)));
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Agregar jugadores", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // Buscador
                  TextField(
                    onChanged: filterPlayers,
                    decoration: InputDecoration(
                      hintText: 'Buscar jugador...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lista de jugadores
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredPlayers.isEmpty
                        ? const Center(child: Text("No hay jugadores disponibles"))
                        : ListView.builder(
                            itemCount: filteredPlayers.length,
                            itemBuilder: (context, i) {
                              final p = filteredPlayers[i];
                              final alreadyAdded = matchPlayers.any((mp) => mp.playerId == p.id);

                              return ListTile(
                                title: Text(p.name),
                                subtitle: p.phone != null ? Text(p.phone!) : null,
                                trailing: ElevatedButton(onPressed: alreadyAdded ? null : () => addPlayer(p), child: Text(alreadyAdded ? "Agregado" : "Agregar")),
                                onTap: alreadyAdded ? null : () => addPlayer(p),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200),
                        child: const Text("Cerrar", style: TextStyle(color: Colors.blueGrey)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
