import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Asumo que tienes este import para AppTheme
// import '../app_theme.dart';

class Input extends FormField<String> {
  final String? hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? labelText;
  final TextStyle? labelStyle;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final bool isPassword;
  final bool required;
  final bool enabled;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign? textAlign;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onIconPressed;
  final IconData? icon;
  final bool dense;

  Input({
    Key? key,
    this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.labelText,
    this.labelStyle,
    this.backgroundColor,
    this.textStyle,
    this.hintStyle,
    this.width,
    this.height = 40.0,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 2.0,
    this.isPassword = false,
    this.required = false,
    this.enabled = true,
    this.maxLines = 1,
    this.inputFormatters,
    this.textAlign,
    this.onChanged,
    this.onSubmitted,
    this.onIconPressed,
    this.icon,
    this.dense = false,
  }) : super(
    key: key,
    validator: (value) {
      if (required && (value == null || value.isEmpty)) {
        return 'Campo requerido.';
      }
      return null;
    },
    builder: (FormFieldState<String> state) {

      final bool isSingleLine = maxLines == 1;
      final double? boxHeight = isSingleLine ? height : null;

      final double verticalPadding = isSingleLine ? 8 : 12;
      final double horizontalPadding = 12;

      // Determinar la acción del teclado (Enter/Return)
      final TextInputAction action = isSingleLine
          ? TextInputAction.done
          : TextInputAction.newline;

      // ✨ CORRECCIÓN CLAVE: Si es multilínea, forzamos el tipo de teclado a multiline
      // para cumplir con la aserción de Flutter y permitir el salto de línea.
      final TextInputType finalKeyboardType = isSingleLine
          ? keyboardType // Si es una sola línea, usamos el tipo de teclado pasado (text, email, etc.)
          : TextInputType.multiline; // Si es multilínea, debe ser multiline.


      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelText != null)
            Text(
              labelText!,
              style: labelStyle ??
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: width,
            height: boxHeight,
            child: TextField(
              controller: controller,
              obscureText: isPassword,

              // 👈 APLICACIÓN DE LA CORRECCIÓN
              keyboardType: finalKeyboardType,

              enabled: enabled,
              minLines: isSingleLine ? 1 : maxLines,
              maxLines: maxLines,
              textAlign: textAlign ?? TextAlign.start,
              style: textStyle ?? const TextStyle(color: Colors.black, fontSize: 13),
              inputFormatters: inputFormatters,

              // Aplicar la acción del teclado
              textInputAction: action,

              // El callback onSubmitted solo tiene sentido si no es multilínea
              onSubmitted: isSingleLine ? onSubmitted : null,

              decoration: InputDecoration(
                hintText: hintText ?? '',
                hintStyle: hintStyle ?? const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: backgroundColor ?? Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  vertical: verticalPadding,
                  horizontal: horizontalPadding,
                ),
                suffixIcon: icon != null
                    ? IconButton(
                  icon: Icon(icon, color: Colors.grey),
                  onPressed: enabled ? onIconPressed : null,
                )
                    : null,

                // Estilos de borde y error (sin cambios)
                border: OutlineInputBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: state.hasError ? Colors.red : borderColor ?? Colors.grey,
                    width: borderWidth,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: state.hasError ? Colors.red : borderColor ?? Colors.grey,
                    width: borderWidth,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: state.hasError ? Colors.red : borderColor ?? Colors.blue,
                    width: borderWidth,
                  ),
                ),
                errorText: state.hasError ? state.errorText : null,
              ),
              onChanged: (value) {
                state.didChange(value);
                if (onChanged != null) {
                  Future.microtask(() => onChanged!(value));
                }
              },
            ),
          ),
        ],
      );
    },
  );
}