import 'package:flutter/material.dart';
import 'package:game_setter/features/courts/domain/entities/court.dart';
import 'package:game_setter/features/courts/presentation/pages/edit_court_page.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/players/presentation/pages/edit_player_page.dart';
import 'features/home/presentation/home_page.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GameSetterApp());
}

class GameSetterApp extends StatelessWidget {
  const GameSetterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Setter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        textTheme: TextTheme(
          // Títulos grandes (pantallas, headers principales)
          displayLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 36), // Uso: Splash screens, landing principal
          displayMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 32), // Uso: Secciones principales
          displaySmall: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 28), // Uso: Subtítulos grandes
          // Encabezados dentro de páginas
          headlineLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 24), // Uso: Títulos de secciones importantes
          headlineMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 20), // Uso: Títulos secundarios
          headlineSmall: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 18), // Uso: Titulos pequeños o tarjetas
          // Texto de cuerpo
          bodyLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400, fontSize: 16), // Uso: Texto normal principal
          bodyMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400, fontSize: 14), // Uso: Texto de cuerpo secundario
          bodySmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400, fontSize: 12), // Uso: Texto auxiliar, notas, pie de página
          // Etiquetas y botones
          labelLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16), // Uso: Botones grandes, etiquetas
          labelMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14), // Uso: Botones estándar, etiquetas secundarias
          labelSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12), // Uso: Pequeñas etiquetas o botones
          // Título de tarjetas, widgets específicos
          titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 18), // Uso: Títulos de card o widget destacados
          titleMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 16), // Uso: Subtítulos dentro de widgets
          titleSmall: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 14), // Uso: Subtítulos pequeños dentro de widgets
        ),
      ),
      home: const HomePage(),
      onGenerateRoute: (settings) {
        if (settings.name == '/editPlayer') {
          final player = settings.arguments as Player;
          return MaterialPageRoute(builder: (_) => EditPlayerPage(player: player));
        }
        if (settings.name == '/editCourt') {
          final court = settings.arguments as Court;
          return MaterialPageRoute(builder: (_) => EditCourtPage(court: court));
        }

        // Fallback
        return MaterialPageRoute(builder: (_) => const HomePage());
      },
    );
  }
}
