import 'package:flutter/material.dart';

class Dropdown<T> extends StatelessWidget {
  final String? labelText;
  final TextStyle? labelStyle;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final Color? dropdownColor;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final bool? enabled;
  final double? maxMenuHeight;

  const Dropdown({
    Key? key,
    required this.items,
    required this.onChanged,
    this.value,
    this.labelText,
    this.labelStyle,
    this.backgroundColor,
    this.textStyle,
    this.dropdownColor,
    this.width,
    this.height = 40,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 2.0,
    this.enabled = true,
    this.maxMenuHeight = 300,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color effectiveBackgroundColor = (enabled == true)
        ? (backgroundColor ?? Colors.white)
        : (backgroundColor ?? Colors.grey).withOpacity(0.3);

    final ValueChanged<T?>? effectiveOnChanged = (enabled == true) ? onChanged : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Text(
            labelText!,
            style: labelStyle ?? const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: borderRadius ?? BorderRadius.circular(8.0),
              border: Border.all(
                color: borderColor ?? Colors.grey,
                width: borderWidth,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  items: items,
                  onChanged: effectiveOnChanged,
                  isExpanded: true,
                  dropdownColor: dropdownColor ?? effectiveBackgroundColor,
                  style: textStyle ?? const TextStyle(color: Colors.black),
                  icon: Icon(
                      Icons.arrow_drop_down,
                      color: borderColor ?? Theme.of(context).primaryColor.withOpacity(enabled == true ? 1.0 : 0.4)
                  ),
                  borderRadius: borderRadius ?? BorderRadius.circular(8.0),
                  menuMaxHeight: maxMenuHeight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}