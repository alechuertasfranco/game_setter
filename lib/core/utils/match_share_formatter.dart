import 'package:game_setter/core/utils/date_formatter.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';

class MatchShareFormatter {
  static String generateMessage(Match match, List<MatchPlayer> players) {
    final buffer = StringBuffer();

    final sportIcon = _getSportIcon(match.sportId);

    buffer.writeln("$sportIcon ${match.sportName}");
    buffer.writeln("");

    if (match.date != null) {
      buffer.writeln("📅 ${DateFormatter.formatDayMonthEs(match.date)}");
    }

    if (match.time != null) {
      buffer.writeln("⏰ ${match.time}");
    }

    if (match.courtName != null && match.courtName!.isNotEmpty) {
      buffer.writeln("📍 ${match.courtName}");
    }

    buffer.writeln("");
    buffer.writeln("Jugadores:");

    for (final mp in players) {
      final name = mp.player?.name ?? "Jugador";
      final attendedIcon = mp.attended ? "✅" : "❌";
      final paidIcon = mp.paid ? "💰" : "";

      buffer.writeln("$attendedIcon $paidIcon $name");
    }

    return buffer.toString();
  }

  static String _getSportIcon(int? sportId) {
    switch (sportId) {
      case 1:
        return "🏐"; // Voley
      case 2:
        return "⚽"; // Fútbol
      case 3:
        return "🏀"; // Basket
      default:
        return "⚽"; // Genérico
    }
  }
}
