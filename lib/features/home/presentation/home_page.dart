import 'package:flutter/material.dart';
import 'package:game_setter/features/players/presentation/pages/players_page.dart';
import 'package:game_setter/features/sports/presentation/pages/select_sport_page.dart';
import 'package:game_setter/features/courts/presentation/pages/courts_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final pages = const [_OrganizeMatchTab(), PlayersPage(), CourtsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sports_volleyball), label: 'Organizar'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Jugadores'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_gymnastics), label: 'Canchas'),
        ],
      ),
    );
  }
}

class _OrganizeMatchTab extends StatelessWidget {
  const _OrganizeMatchTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organizar Partido')),
      body: Center(
        child: FilledButton(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectSportPage()));
          },
          child: const Text('Seleccionar Deporte', style: TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}
