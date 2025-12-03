import 'package:flutter/material.dart' hide Notification;
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/notifications/presentarion/widget/notification_form.dart';

class SendNotificationPage extends StatelessWidget {
  final Match match;

  const SendNotificationPage({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar notificación')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: NotificationForm(match: match),
        ),
      ),
    );
  }
}
