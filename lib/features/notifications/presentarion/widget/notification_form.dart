import 'package:flutter/material.dart' hide Notification;
import 'package:game_setter/features/notifications/presentarion/widget/message_input.dart';
import 'package:game_setter/features/notifications/presentarion/widget/notification_buttons.dart';
import 'package:game_setter/features/notifications/presentarion/widget/players_list.dart';
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
    final players = await MatchRepository().getMatchPlayersDetailed(widget.match.id!);
    final court = await MatchRepository().getCourt(widget.match.courtId);

    setState(() {
      allPlayers = players;
      matchCourt = court;
    });

    updateRecipients();
    updateDefaultMessage();
  }

  MatchPlayer? get nextPlayerToSend {
    try {
      return allPlayers.firstWhere((p) => selectedPlayers.contains(p));
    } catch (_) {
      return null;
    }
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

  Future<void> sendSinglePlayerWhatsApp(BuildContext context) async {
    final player = nextPlayerToSend;
    if (player == null) return;
    await sendWhatsApp(context, player, messageController.text);
    setState(() {
      selectedPlayers.remove(player);
    });
  }

  Future<void> sendWhatsApp(BuildContext context, MatchPlayer selectedPlayer, String message) async {
    if (message.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ingrese un mensaje', style: Theme.of(context).textTheme.bodyLarge)));
      return;
    }

    final pendingRecipients = <Map<String, dynamic>>[];
    pendingRecipients.add({'id': selectedPlayer.playerId, 'phone': selectedPlayer.player?.phone, 'name': selectedPlayer.player?.name, 'type': 'player'});

    if (type == 'Reserva' && matchCourt != null && matchCourt?.phone != null && matchCourt!.phone!.isNotEmpty) {
      pendingRecipients.add({'id': null, 'phone': matchCourt!.phone, 'name': 'Cancha', 'type': 'court'});
    }

    if (pendingRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No hay destinatarios con número de WhatsApp', style: Theme.of(context).textTheme.bodyLarge)));
      return;
    }

    while (pendingRecipients.isNotEmpty) {
      final recipient = pendingRecipients.first;

      await NotificationRepository().insertNotification(
        matchId: widget.match.id,
        playerId: recipient['type'] == 'player' ? recipient['id'] : null,
        courtId: recipient['type'] == 'court' ? matchCourt?.id : null,
        type: type,
        message: message,
      );

      // Preparar número y URL de WhatsApp
      final rawPhone = recipient['phone'];
      if (rawPhone != null && rawPhone.isNotEmpty) {
        final phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
        if (phone.isNotEmpty) {
          final encodedMessage = Uri.encodeComponent(message);
          final whatsappUrl = Uri.parse('https://wa.me/$phone?text=$encodedMessage');

          try {
            await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('No se pudo abrir WhatsApp para ${recipient['name'] ?? 'destinatario'}', style: Theme.of(context).textTheme.bodyLarge)));
          }
        }
      }

      pendingRecipients.removeAt(0);
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notificación enviada por WhatsApp', style: Theme.of(context).textTheme.bodyLarge)));
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
          decoration: InputDecoration(labelText: "Tipo de notificación", labelStyle: textTheme.bodyLarge),
          items: ['Invitación', 'Confirmación', 'Cobro', 'Reserva', 'Info', 'General']
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, style: textTheme.bodyLarge),
                ),
              )
              .toList(),
          onChanged: (val) => updateRecipients(val),
        ),
        if (type == 'Invitación' || type == 'Confirmación')
          Row(
            children: [
              Transform.scale(
                scale: 0.7,
                child: Checkbox(value: includeMapLink, onChanged: (val) => toggleIncludeMapLink(val!), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
              Text('Incluir enlace de Maps', style: textTheme.bodyMedium),
            ],
          ),
        const SizedBox(height: 24),
        Text('Destinatarios:', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        Expanded(
          child: PlayersList(allPlayers: allPlayers, selectedPlayers: selectedPlayers, matchCourt: matchCourt, type: type, toggleSelection: togglePlayerSelection),
        ),
        const SizedBox(height: 12),
        MessageInput(controller: messageController),
        const SizedBox(height: 12),
        NotificationButtons(
          onSendWhatsApp: () => sendSinglePlayerWhatsApp(context),
          buttonLabel: nextPlayerToSend == null ? null : "Enviar WhatsApp a ${nextPlayerToSend!.player?.name}",
        ),
      ],
    );
  }
}
