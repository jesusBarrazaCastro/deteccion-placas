import 'package:flutter/material.dart';

import '../app_theme.dart';

class Button extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData? icon;

  const Button({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textStyle,
    this.width,
    this.height = 40,
    this.borderRadius,
    this.icon
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.light.primary,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8.0),
          ),
          surfaceTintColor: Colors.white
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            if(icon != null)...[
              Icon(icon!, color: Colors.white,),
            ],
            Expanded(
              child: Text(
                text,
                style: textStyle ?? const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
