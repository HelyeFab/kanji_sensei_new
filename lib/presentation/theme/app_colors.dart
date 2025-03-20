import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Navy blue from the design
  static const Color primary = Color(0xFF1E2A5A);
  static const Color primaryLight = Color(0xFF3A4980);
  static const Color primaryDark = Color(0xFF0E1A40);

  // Secondary colors - Light pink from the design
  static const Color secondary = Color(0xFFF8C4C6);
  static const Color secondaryLight = Color(0xFFFAD4D6);
  static const Color secondaryDark = Color(0xFFF6B4B6);

  // Background colors
  static const Color background = Color(0xFFF8C4C6); // Light pink background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD90429);

  // Text colors
  static const Color textPrimary = Color(0xFF1E2A5A); // Navy blue text
  static const Color textSecondary = Color(0xFF5A6793); // Lighter navy for secondary text
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on primary
  static const Color textOnSecondary = Color(0xFF1E2A5A); // Navy text on secondary (pink)

  // Card colors
  static const Color cardBackground = Color(0xFFFFFFFF); // White card background
  static const Color cardBorder = Color(0xFF1E2A5A); // Navy border

  // Tag colors (for part of speech tags)
  static const Color tagBackground = Color(0xFF1E2A5A); // Navy background
  static const Color tagText = Color(0xFFFFFFFF); // White text

  // Japanese theme accents
  static const Color inkBlack = Color(0xFF1A1A1A);
  static const Color paperWhite = Color(0xFFF7F3E9);
  static const Color sakuraPink = Color(0xFFF8C4C6); // Updated to match design
  static const Color matcha = Color(0xFF89A894);
  static const Color lightGray = Color.fromARGB(255, 182, 180, 180);
}
