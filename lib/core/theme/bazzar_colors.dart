import 'package:flutter/material.dart';

/// Shared visual tokens for all Bazzar presentation layers.
abstract final class BazzarColors {
  static const primary = Color(0xFF7C3AED);
  static const primaryDark = Color(0xFF6D28D9);
  static const ink = Color(0xFF292039);
  static const body = Color(0xFF50475E);
  static const muted = Color(0xFF71677E);
  static const background = Color(0xFFF8F7FC);
  static const surface = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF0ECF7);
  static const border = Color(0xFFE5DFF0);
  static const lavender = Color(0xFFEDE5FC);
  static const night = Color(0xFF211631);
  static const hero = LinearGradient(
    colors: [Color(0xFF30205C), primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
