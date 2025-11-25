import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'input.dart'; // Assuming the Input widget is imported from your custom file.

class NumericInput extends Input {
  final void Function(String)? onChanged;

  // NumericInput specific properties can be added here if needed.

  NumericInput({
    Key? key,
    String? hintText,
    required TextEditingController controller,
    TextStyle? textStyle,
    Color? backgroundColor,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    Color? borderColor,
    double borderWidth = 2.0,
    bool required = false,
    bool enabled = true,
    TextStyle? hintStyle,
    bool isPassword = false,
    String? labelText,
    int? maxDecimalPlaces = 2,
    bool showCurrencySymbol = false,
    this.onChanged,
  }) : super(
    key: key,
    controller: controller,
    labelText: labelText,
    keyboardType: TextInputType.numberWithOptions(decimal: true), // Allow decimal for money
    inputFormatters: [
      TextInputFormatter.withFunction((oldValue, newValue) {
        String newText = newValue.text;

        // Create a regular expression based on the maxDecimalPlaces
        final regExpString = r'^\d*\.?\d{0,' + maxDecimalPlaces.toString() + r'}$';
        final validInput = RegExp(regExpString);

        // Validate the input based on the regex
        if (validInput.hasMatch(newText)) {
          // Find the position of the cursor in the original text
          final cursorPosition = newValue.selection.base.offset;

          // Update the text with the new value and set the cursor at the correct position
          final newTextWithCursor = newValue.copyWith(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length), // Ensure cursor is at the end
          );

          return newTextWithCursor;
        }
        return oldValue; // Reject the new value if it's invalid
      }),
    ],
    textAlign: TextAlign.end,
    hintText: hintText ?? '', // Default hint text for numeric input
    textStyle: textStyle ?? const TextStyle(color: Colors.black),
    backgroundColor: backgroundColor,
    width: width,
    //height: height,
    borderRadius: borderRadius,
    borderColor: borderColor,
    borderWidth: borderWidth,
    required: required,
    enabled: enabled,
    hintStyle: hintStyle,
    isPassword: isPassword,
    onChanged: onChanged
  );
}
