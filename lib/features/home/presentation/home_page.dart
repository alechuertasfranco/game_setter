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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) {
          final scale = Tween<double>(begin: 0.95, end: 1).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Color(0xFFE3F2FD),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_volleyball, color: Colors.blueGrey),
            selectedIcon: Icon(Icons.sports_volleyball, color: Color(0xFF3695D4)),
            label: 'Organizar',
          ),
          NavigationDestination(
            icon: Icon(Icons.people, color: Colors.blueGrey),
            selectedIcon: Icon(Icons.people, color: Color(0xFF3695D4)),
            label: 'Jugadores',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on, color: Colors.blueGrey),
            selectedIcon: Icon(Icons.location_on, color: Color(0xFF3695D4)),
            label: 'Canchas',
          ),
        ],
      ),
    );
  }
}

class _OrganizeMatchTab extends StatelessWidget {
  const _OrganizeMatchTab();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Organiza tu próximo partido\nrápido y fácil', textAlign: TextAlign.center, style: textTheme.headlineSmall),
                  const SizedBox(height: 40),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectSportPage()));
                    },
                    child: Text('Empezar', style: textTheme.bodyLarge?.copyWith(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
