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
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          // Desplazamiento horizontal + fade
          final offsetAnimation = Tween<Offset>(begin: Offset(_currentIndex > 0 ? 1 : -1, 0), end: Offset.zero).animate(animation);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: pages[_currentIndex],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sports_volleyball), label: 'Organizar'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Jugadores'),
          NavigationDestination(icon: Icon(Icons.location_on), label: 'Canchas'),
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // AppBar simulado
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Text('Organizar Partido', style: textTheme.headlineSmall),
            ),

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
      ),
    );
  }
}
