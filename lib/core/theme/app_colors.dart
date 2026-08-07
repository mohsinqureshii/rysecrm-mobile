import 'package:flutter/material.dart';

/// RYSE design tokens, modeled on the Salesforce Lightning Design System.
class AppColors {
  AppColors._();

  // Brand
  static const Color brand = Color(0xFF0176D3); // Salesforce-style action blue
  static const Color brandDark = Color(0xFF014486);
  static const Color navy = Color(0xFF032D60); // deep header navy
  static const Color navyLight = Color(0xFF16325C);
  static const Color cloud = Color(0xFFEAF5FE); // light blue wash
  static const Color brandAccent = Color(0xFF1B96FF);

  // Surfaces
  static const Color background = Color(0xFFF3F5F9);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE5E5E5);
  static const Color borderStrong = Color(0xFFC9C9C9);

  // Text
  static const Color textPrimary = Color(0xFF181818);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color textTertiary = Color(0xFF747474);
  static const Color textOnDark = Colors.white;

  // Semantic
  static const Color success = Color(0xFF2E844A);
  static const Color successLight = Color(0xFFEBF7E6);
  static const Color error = Color(0xFFBA0517);
  static const Color errorBright = Color(0xFFEA001E);
  static const Color errorLight = Color(0xFFFEF1EE);
  static const Color warning = Color(0xFFFE9339);
  static const Color warningDark = Color(0xFFA96404);
  static const Color warningLight = Color(0xFFFEF4E8);
  static const Color info = Color(0xFF706E6B);

  // Record-type colors (SLDS standard object icons)
  static const Color lead = Color(0xFFF88962);
  static const Color contact = Color(0xFFA094ED);
  static const Color account = Color(0xFF7F8DE1);
  static const Color opportunity = Color(0xFFFCB95B);
  static const Color task = Color(0xFF4BC076);
  static const Color event = Color(0xFFEB7092);
  static const Color campaign = Color(0xFFF49756);
  static const Color report = Color(0xFF7F8DE1);
  static const Color ai = Color(0xFF9050E9); // Einstein-style purple

  // AI gradient (RYSE Intelligence)
  static const List<Color> aiGradient = [Color(0xFF9050E9), Color(0xFF5867E8)];

  // Chart palette
  static const List<Color> chartPalette = [
    Color(0xFF1B96FF),
    Color(0xFF9050E9),
    Color(0xFF06A59A),
    Color(0xFFFE9339),
    Color(0xFFEB7092),
    Color(0xFF7F8DE1),
    Color(0xFF2E844A),
  ];

  /// Stable avatar color derived from a name.
  static Color avatarColor(String seed) {
    const palette = [
      Color(0xFF0176D3),
      Color(0xFF9050E9),
      Color(0xFF06A59A),
      Color(0xFFE26E00),
      Color(0xFFB60554),
      Color(0xFF7F8DE1),
      Color(0xFF3BA755),
    ];
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }
}
