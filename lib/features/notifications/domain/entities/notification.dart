import 'package:game_setter/core/utils/date_formatter.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/courts/domain/entities/court.dart';

enum NotificationType { invitacion, confirmacion, cobro, reserva, info, general }

class Notification {
  final int id;
  final int? matchId;
  final String? playerId;
  final int? courtId;
  final NotificationType type;
  final String message;
  final DateTime timestamp;

  // Opcionales para acceso directo
  final Match? match;
  final Player? player;
  final Court? court;

  Notification({required this.id, this.matchId, this.playerId, this.courtId, required this.type, String? message, DateTime? timestamp, this.match, this.player, this.court})
    : message = message ?? defaultMessage(type, match: match, court: court),
      timestamp = timestamp ?? DateTime.now();

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] as int,
      matchId: map['match_id'] as int?,
      playerId: map['player_id'] as String?,
      courtId: map['court_id'] as int?,
      type: _typeFromString(map['type'] as String),
      message: map['message'] as String?,
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp'] as String) : null,
      match: map['match'] as Match?,
      player: map['player'] as Player?,
      court: map['court'] as Court?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'match_id': matchId, 'player_id': playerId, 'court_id': courtId, 'type': _typeToString(type), 'message': message, 'timestamp': timestamp.toIso8601String()};
  }

  Notification copyWith({
    int? id,
    int? matchId,
    String? playerId,
    int? courtId,
    NotificationType? type,
    String? message,
    DateTime? timestamp,
    Match? match,
    Player? player,
    Court? court,
  }) {
    return Notification(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
      courtId: courtId ?? this.courtId,
      type: type ?? this.type,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      match: match ?? this.match,
      player: player ?? this.player,
      court: court ?? this.court,
    );
  }

  /// Mensajes por defecto dinámicos incluyendo fecha, hora y cancha si aplica
  static String defaultMessage(NotificationType type, {Match? match, Court? court}) {
    final formattedDate = DateFormatter.formatDayEs(match?.date);
    final formattedTime = DateFormatter.formatTimeEs(match?.time);

    String dateStr = formattedDate != null ? ' el $formattedDate' : ', estoy definiendo el día';
    String timeStr = formattedTime != null ? ' a las $formattedTime' : ', estoy definiendo la hora';

    final courtInfo = (court != null && court.name.isNotEmpty) ? ' en ${court.name}' : '';

    switch (type) {
      case NotificationType.invitacion:
        return 'Holas, sale partido$dateStr$timeStr$courtInfo, la haces?';
      case NotificationType.confirmacion:
        return 'Hello, no te olvides partido$dateStr$timeStr$courtInfo, confirmado';
      case NotificationType.cobro:
        return 'Hey, no te olvides de pasarme el pago de la cancha de$dateStr porfas';
      case NotificationType.reserva:
        return 'Hola, disculpa tiene cancha disponible para el$dateStr$timeStr?';
      case NotificationType.info:
        return 'Holas, ...';
      case NotificationType.general:
        return 'Holas, ...';
    }
  }

  static NotificationType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'invitacion':
        return NotificationType.invitacion;
      case 'confirmacion':
        return NotificationType.confirmacion;
      case 'cobro':
        return NotificationType.cobro;
      case 'reserva':
        return NotificationType.reserva;
      case 'info':
        return NotificationType.info;
      case 'general':
      default:
        return NotificationType.general;
    }
  }

  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.invitacion:
        return 'Invitación';
      case NotificationType.confirmacion:
        return 'Confirmación';
      case NotificationType.cobro:
        return 'Cobro';
      case NotificationType.reserva:
        return 'Reserva';
      case NotificationType.info:
        return 'Info';
      case NotificationType.general:
        return 'General';
    }
  }
}
