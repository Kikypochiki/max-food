import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String friendlyAuthErrorMessage(
  Object? error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('wrong password')) {
      return 'Incorrect email or password. Please try again.';
    }

    if (message.contains('email not confirmed')) {
      return 'Please confirm your email before logging in.';
    }

    if (message.contains('already') || message.contains('registered')) {
      return 'This email is already registered. Try logging in instead.';
    }

    if (message.contains('invalid email')) {
      return 'Please use a valid email address.';
    }

    if (message.contains('password')) {
      return 'Password must be at least 6 characters.';
    }

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('host lookup')) {
      return 'Network error. Check your connection and try again.';
    }

    return error.message;
  }

  return fallback;
}

Future<void> showAuthErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(
            'OK',
            style: TextStyle(
              color: Color(0xFF29A300),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
