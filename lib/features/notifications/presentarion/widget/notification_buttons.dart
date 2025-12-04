import 'package:flutter/material.dart';

class NotificationButtons extends StatelessWidget {
  final VoidCallback onSendWhatsApp;

  const NotificationButtons({super.key, required this.onSendWhatsApp});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onSendWhatsApp,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Colors.green),
              backgroundColor: Colors.green[50],
            ),
            icon: const Icon(Icons.chat_bubble, color: Colors.green),
            label: Text(
              'Enviar por WhatsApp',
              style: textTheme.bodyMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
