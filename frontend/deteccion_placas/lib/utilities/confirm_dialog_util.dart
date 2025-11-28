import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class ConfirmDialog {
  /// Muestra un diálogo de confirmación con animación y devuelve true si el usuario acepta.
  static Future<bool> confirm(
      BuildContext context, {
        required String title,
        required String message,
        String confirmText = 'Aceptar',
        String cancelText = 'Cancelar',
        DialogType dialogType = DialogType.question, // Tipo de ícono animado
        AnimType animType = AnimType.scale, // Animación de aparición
      }) async {
    bool confirmed = false;

    await AwesomeDialog(
      context: context,
      width: 500,
      dialogType: dialogType,
      animType: animType,
      title: title,
      desc: message,
      btnCancelText: cancelText,
      btnOkText: confirmText,
      btnCancelOnPress: () {
        confirmed = false;
      },
      btnOkOnPress: () {
        confirmed = true;
      },
      btnOkColor: Colors.green,
      btnCancelColor: Colors.red,
      dismissOnTouchOutside: false,
      borderSide: const BorderSide(color: Colors.transparent),
      //borderRadius: 16,
      buttonsBorderRadius: const BorderRadius.all(Radius.circular(12)),
    ).show();

    return confirmed;
  }

  static Future<void> error(
      BuildContext context, {
        required String title,
        required String message,
        String okText = 'Entendido', // Nombre sugerido para el botón
        AnimType animType = AnimType.scale, // Animación de aparición
      }) async {
    await AwesomeDialog(
      context: context,
      width: 500,
      dialogType: DialogType.error, // Icono de error
      animType: animType,
      title: title,
      desc: message,
      btnOkText: okText,
      btnOkOnPress: () {}, // No hace falta lógica, solo cierra el diálogo
      btnOkColor: Colors.red, // Color rojo para el botón de error
      dismissOnTouchOutside: true, // Se puede cerrar tocando fuera si es un error simple
      borderSide: const BorderSide(color: Colors.transparent),
      buttonsBorderRadius: const BorderRadius.all(Radius.circular(12)),
    ).show();
  }
}
