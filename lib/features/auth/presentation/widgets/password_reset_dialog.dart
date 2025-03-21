import 'package:flutter/material.dart';

class PasswordResetDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;

  const PasswordResetDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  static void showResetEmailSent(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PasswordResetDialog(
        title: 'Password Reset Email Sent',
        message: 'Check your email for instructions to reset your password.',
        icon: Icons.check_circle,
        iconColor: Colors.green,
      ),
    );
  }

  static void showEmailRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PasswordResetDialog(
        title: 'Email Required',
        message: 'Please enter your email address to reset your password.',
        icon: Icons.info,
        iconColor: Colors.blue,
      ),
    );
  }
}
