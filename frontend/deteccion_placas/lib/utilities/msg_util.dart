import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

class MsgtUtil {
  /// Success toast
  /// Retorna la instancia de Flushbar para poder controlarla si es necesario.
  static Flushbar showSuccess(BuildContext context, String message) {
    return _showFlushbar(
      context,
      message,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle,
      // Los mensajes de éxito se cierran automáticamente
      duration: const Duration(seconds: 2),
    );
  }

  /// Error toast
  /// Retorna la instancia de Flushbar para poder controlarla si es necesario.
  static Flushbar showError(BuildContext context, String message) {
    return _showFlushbar(
      context,
      message,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error,
      // Los mensajes de error suelen durar un poco más para que el usuario pueda leer
      duration: const Duration(seconds: 4),
    );
  }

  /// Warning toast
  /// Retorna la instancia de Flushbar para poder controlarla si es necesario.
  static Flushbar showWarning(BuildContext context, String message) {
    return _showFlushbar(
      context,
      message,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.warning,
      // Los warnings duran un poco más
      duration: const Duration(seconds: 3),
    );
  }

  /// Private helper
  static Flushbar _showFlushbar(
      BuildContext context,
      String message, {
        required Color backgroundColor,
        required IconData icon,
        Duration? duration, // Permitir duración variable
      }) {
    final flushbar = Flushbar(
      message: message,
      icon: Icon(
        icon,
        size: 28.0,
        color: Colors.white,
      ),
      duration: duration, // Usar la duración pasada (puede ser null para ser permanente)
      backgroundColor: backgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      borderRadius: BorderRadius.circular(12),
      flushbarPosition: FlushbarPosition.BOTTOM,
      animationDuration: const Duration(milliseconds: 300),
      isDismissible: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      maxWidth: 800,
    );

    // Mostrar la barra inmediatamente
    flushbar.show(context);

    // Retornar la instancia para control externo
    return flushbar;
  }
}