import 'package:flutter/material.dart';
import 'dart:ui';

@immutable
class AppTheme extends ThemeExtension<AppTheme> {
  // Colors
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color success;
  final Color warning;
  final Color error;

  // Typography
  final TextStyle title1;
  final TextStyle title2;
  final TextStyle body;
  final TextStyle bodyBold;
  final TextStyle caption;

  // Spacing & Radius
  final double spacing;
  final double radius;

  const AppTheme({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.success,
    required this.warning,
    required this.error,
    required this.title1,
    required this.title2,
    required this.body,
    required this.caption,
    required this.spacing,
    required this.radius, required this.bodyBold,
  });

  @override
  AppTheme copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? success,
    Color? warning,
    Color? error,
    TextStyle? title1,
    TextStyle? title2,
    TextStyle? body,
    TextStyle? bodyBold,
    TextStyle? caption,
    double? spacing,
    double? radius,
  }) {
    return AppTheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      title1: title1 ?? this.title1,
      title2: title2 ?? this.title2,
      body: body ?? this.body,
      bodyBold: bodyBold ?? this.bodyBold,
      caption: caption ?? this.caption,
      spacing: spacing ?? this.spacing,
      radius: radius ?? this.radius,
    );
  }

  @override
  AppTheme lerp(ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) return this;
    return AppTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      title1: TextStyle.lerp(title1, other.title1, t)!,
      title2: TextStyle.lerp(title2, other.title2, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyBold: TextStyle.lerp(body, other.body, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      spacing: lerpDouble(spacing, other.spacing, t)!,
      radius: lerpDouble(radius, other.radius, t)!,
    );
  }

  // --- Presets ---
  static AppTheme light = AppTheme(
    primary: Colors.indigo,
    secondary: Colors.blueGrey,
    background: Colors.white,
    surface: Colors.grey[100]!,
    success: Colors.green,
    warning: Colors.orange,
    error: Colors.red,
    title1: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
    title2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    body: const TextStyle(fontSize: 16),
    bodyBold: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    caption: const TextStyle(fontSize: 14, color: Colors.grey),
    spacing: 8,
    radius: 12,
  );

  static AppTheme dark = AppTheme(
    primary: Colors.indigo,
    secondary: Colors.teal,
    background: Colors.black,
    surface: Colors.grey[850]!,
    success: Colors.greenAccent,
    warning: Colors.orangeAccent,
    error: Colors.redAccent,
    title1: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
    title2: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white70),
    body: const TextStyle(fontSize: 16, color: Colors.white),
    bodyBold: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
    caption: const TextStyle(fontSize: 14, color: Colors.grey),
    spacing: 8,
    radius: 12,
  );
}
