import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DateFormatter {
  /// Formatea un string de fecha "2025-12-14" → "viernes 14"
  /// Si la fecha es hoy → "hoy"
  static String? formatDayEs(String? isoDate) {
    if (isoDate == null) return null;

    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();

      // Normalizamos ambos para comparar solo fechas sin hora
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(date.year, date.month, date.day);

      if (target == today) return 'hoy';
      return DateFormat('EEEE dd', 'es_ES').format(date);
    } catch (e) {
      debugPrint("ERROR parsing date: $e");
      return null;
    }
  }

  static String? formatDayMonthEs(String? isoDate) {
    if (isoDate == null) return null;

    try {
      final date = DateTime.parse(isoDate);
      String formatted = DateFormat('EEEE dd, MMMM', 'es_ES').format(date);
      formatted = formatted.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word).join(' ');
      return formatted;
    } catch (e) {
      debugPrint("ERROR parsing date: $e");
      return null;
    }
  }

  /// Formatea un string de hora "17:30" → "5:30pm"
  static String? formatTimeEs(String? time24h) {
    if (time24h == null) return null;

    try {
      final parsed = DateFormat('HH:mm').parse(time24h);
      final formatted = DateFormat('h:mma', 'es_ES').format(parsed).toLowerCase();
      return formatted;
    } catch (e) {
      debugPrint("ERROR parsing time: $e");
      return null;
    }
  }

  /// Formato genérico dd/MM/yyyy
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formato genérico 5:30 PM para TimeOfDay
  static String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  /// Combina fecha y hora
  static DateTime combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
