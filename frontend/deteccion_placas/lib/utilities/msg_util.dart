import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

class MsgtUtil {
  /// Success toast
  static Future<void> showSuccess(BuildContext context, String message) async {
    _showFlushbar(
      context,
      message,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle,
    );
  }

  /// Error toast
  static Future<void> showError(BuildContext context, String message) async {
    _showFlushbar(
      context,
      message,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error,
    );
  }

  /// Warning toast
  static Future<void> showWarning(BuildContext context, String message) async {
    _showFlushbar(
      context,
      message,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.warning,
    );
  }

  /// Private helper
  static Future<void> _showFlushbar(
      BuildContext context,
      String message, {
        required Color backgroundColor,
        required IconData icon,
      }) async {
    await Flushbar(
      message: message,
      icon: Icon(
        icon,
        size: 28.0,
        color: Colors.white,
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: backgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      borderRadius: BorderRadius.circular(12),
      flushbarPosition: FlushbarPosition.BOTTOM,
      animationDuration: const Duration(milliseconds: 300),
      isDismissible: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      maxWidth: 800,
    ).show(context);
  }
}
