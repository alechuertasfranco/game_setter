import 'package:flutter/material.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/players/presentation/pages/edit_player_page.dart';
import 'features/home/presentation/home_page.dart';

void main() {
  runApp(const GameSetterApp());
}

class GameSetterApp extends StatelessWidget {
  const GameSetterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Setter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const HomePage(),
      onGenerateRoute: (settings) {
        if (settings.name == '/editPlayer') {
          final player = settings.arguments as Player;
          return MaterialPageRoute(builder: (_) => EditPlayerPage(player: player));
        }

        // fallback
        return MaterialPageRoute(builder: (_) => const HomePage());
      },
    );
  }
}
