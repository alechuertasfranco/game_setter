import 'package:flutter/material.dart' hide Notification;
import 'package:url_launcher/url_launcher.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/matches/data/match_repository.dart';
import 'package:game_setter/features/notifications/data/notification_repository.dart';
import 'package:game_setter/features/courts/domain/entities/court.dart';
import 'package:game_setter/features/notifications/domain/entities/notification.dart';

class NotificationForm extends StatefulWidget {
  final Match match;

  const NotificationForm({super.key, required this.match});

  @override
  State<NotificationForm> createState() => _NotificationFormState();
}

class _NotificationFormState extends State<NotificationForm> {
  String type = 'Invitación';
  List<MatchPlayer> allPlayers = [];
  List<MatchPlayer> selectedPlayers = [];
  Court? matchCourt;
  bool includeMapLink = false;
  final TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    final players = await MatchRepository().getMatchPlayersDetailed(widget.match.id);
    final court = await MatchRepository().getCourt(widget.match.courtId);

    setState(() {
      allPlayers = players;
      matchCourt = court;
    });

    updateRecipients();
    updateDefaultMessage();
  }

  void updateRecipients([String? newType]) {
    String currentType = newType ?? type;
    List<MatchPlayer> initial = [];

    switch (currentType) {
      case 'Invitación':
      case 'Confirmación':
        initial = allPlayers.where((p) => !p.attended).toList();
        break;
      case 'Cobro':
        initial = allPlayers.where((p) => p.attended && !p.paid).toList();
        break;
      case 'Reserva':
        initial = [];
        break;
      case 'Info':
      case 'General':
        initial = List.from(allPlayers);
        break;
    }

    setState(() {
      type = currentType;
      selectedPlayers = initial;
    });

    updateDefaultMessage();
  }

  void updateDefaultMessage() {
    NotificationType nType = _mapStringToNotificationType(type);
    String defaultMsg = Notification.defaultMessage(nType, match: widget.match, court: matchCourt);

    if (includeMapLink && (type == 'Invitación' || type == 'Confirmación')) {
      final location = matchCourt?.location ?? '';
      if (location.isNotEmpty) {
        defaultMsg += '\nCancha: $location';
      }
    }

    messageController.text = defaultMsg;
  }

  void toggleIncludeMapLink(bool value) {
    setState(() => includeMapLink = value);
    updateDefaultMessage();
  }

  void togglePlayerSelection(MatchPlayer player) {
    setState(() {
      if (selectedPlayers.contains(player)) {
        selectedPlayers.remove(player);
      } else {
        selectedPlayers.add(player);
      }
    });
  }

  Future<void> sendNotification() async {
    if (messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un mensaje')));
      return;
    }

    for (var player in selectedPlayers) {
      await NotificationRepository().insertNotification(matchId: widget.match.id, playerId: player.playerId, courtId: null, type: type, message: messageController.text);
    }

    if (type == 'Reserva' && matchCourt != null) {
      await NotificationRepository().insertNotification(matchId: widget.match.id, playerId: null, courtId: matchCourt!.id, type: type, message: messageController.text);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notificación enviada')));
    Navigator.pop(context, true);
  }

  Future<void> sendWhatsApp(BuildContext context, List<MatchPlayer> selectedPlayers, String message) async {
    if (selectedPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione al menos un destinatario')));
      return;
    }

    for (var player in selectedPlayers) {
      final rawPhone = player.player?.phone;
      if (rawPhone == null || rawPhone.isEmpty) continue;

      // Limpia el número: solo dígitos, formato internacional
      final phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (phone.isEmpty) continue;

      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = Uri.parse('https://wa.me/$phone?text=$encodedMessage');

      try {
        // No usamos canLaunchUrl porque a veces devuelve false en emuladores
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir WhatsApp para ${player.player?.name ?? phone}')));
      }
    }
  }

  NotificationType _mapStringToNotificationType(String type) {
    switch (type) {
      case 'Invitación':
        return NotificationType.invitacion;
      case 'Confirmación':
        return NotificationType.confirmacion;
      case 'Cobro':
        return NotificationType.cobro;
      case 'Reserva':
        return NotificationType.reserva;
      case 'Info':
        return NotificationType.info;
      case 'General':
      default:
        return NotificationType.general;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: type,
          decoration: const InputDecoration(labelText: "Tipo de notificación"),
          items: ['Invitación', 'Confirmación', 'Cobro', 'Reserva', 'Info', 'General'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (val) => updateRecipients(val),
        ),
        const SizedBox(height: 12),
        if (type == 'Invitación' || type == 'Confirmación')
          Row(
            children: [
              Checkbox(value: includeMapLink, onChanged: (val) => toggleIncludeMapLink(val!)),
              const Text('Incluir enlace de Maps'),
            ],
          ),
        const SizedBox(height: 12),
        const Text('Destinatarios:', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: ListView(
            children: [
              if (type == 'Reserva' && matchCourt != null) ListTile(leading: const Icon(Icons.location_on), title: Text('Cancha: ${matchCourt!.name}')),
              ...allPlayers.map(
                (p) => CheckboxListTile(
                  title: Text(p.player != null ? '${p.player?.name} - ${p.player?.phone}' : p.playerId, style: textTheme.bodyMedium),
                  value: selectedPlayers.contains(p),
                  onChanged: (_) => togglePlayerSelection(p),
                ),
              ),
            ],
          ),
        ),
        TextField(
          controller: messageController,
          decoration: InputDecoration(labelText: 'Mensaje', border: OutlineInputBorder(), alignLabelWithHint: true),
          maxLines: 5,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: sendNotification, child: const Text('Enviar')),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => sendWhatsApp(context, selectedPlayers, messageController.text),
            icon: const Icon(Icons.chat_bubble, color: Colors.green),
            label: const Text('Enviar por WhatsApp', style: TextStyle(color: Colors.green)),
          ),
        ),
      ],
    );
  }
}
