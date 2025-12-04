import 'package:flutter/material.dart';

class NotificationButtons extends StatelessWidget {
  final VoidCallback onSendWhatsApp;
  final String? buttonLabel;

  const NotificationButtons({super.key, required this.onSendWhatsApp, this.buttonLabel});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final bool isDisabled = buttonLabel == null;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isDisabled ? null : onSendWhatsApp,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: isDisabled ? null : BorderSide(color: Colors.green),
            ),
            icon: Icon(Icons.chat_bubble, color: isDisabled ? Colors.grey : Colors.green),
            label: Text(
              isDisabled ? "Selecciona un jugador" : buttonLabel!,
              style: textTheme.bodyLarge?.copyWith(color: isDisabled ? Colors.grey : Colors.green, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
