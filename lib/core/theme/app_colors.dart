import 'package:flutter/material.dart';

/// RYSE design tokens — a charcoal-black theme with the brand purple accent,
/// matching the RYSE web product (near-black surfaces, #7C3AED purple, the
/// "ryse" triangle mark).
class AppColors {
  AppColors._();

  // Brand — RYSE purple
  static const Color brand = Color(0xFF8B5CF6); // primary purple (on dark)
  static const Color brandStrong = Color(0xFF7C3AED);
  static const Color brandDark = Color(0xFF6D28D9);
  static const Color brandAccent = Color(0xFFA78BFA);

  // Dark surfaces (near-black)
  static const Color background = Color(0xFF0A0D14); // scaffold, near-black
  static const Color surface = Color(0xFF141821); // cards
  static const Color surfaceAlt = Color(0xFF1B2130); // raised / inputs
  static const Color header = Color(0xFF0E121C); // app bars & headers
  static const Color logoTile = Color(0xFF0F1729); // brand tile behind the mark
  static const Color border = Color(0xFF262D3A);
  static const Color borderStrong = Color(0xFF333B4A);

  // Purple-tinted wash (replaces the old light-blue "cloud")
  static const Color cloud = Color(0xFF1A1730);

  // Text
  static const Color textPrimary = Color(0xFFF4F6FB);
  static const Color textSecondary = Color(0xFFA6AEC0);
  static const Color textTertiary = Color(0xFF737B8C);
  static const Color textOnDark = Colors.white;

  // Semantic (tuned for dark)
  static const Color success = Color(0xFF34D399);
  static const Color successLight = Color(0xFF10251E);
  static const Color error = Color(0xFFF87171);
  static const Color errorBright = Color(0xFFF05252);
  static const Color errorLight = Color(0xFF2A1518);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFF2A2110);
  static const Color info = Color(0xFF94A3B8);

  // Record-type colors (vibrant on dark)
  static const Color lead = Color(0xFFFB7185);
  static const Color contact = Color(0xFFA78BFA);
  static const Color account = Color(0xFF60A5FA);
  static const Color opportunity = Color(0xFFFBBF24);
  static const Color task = Color(0xFF34D399);
  static const Color event = Color(0xFFF472B6);
  static const Color campaign = Color(0xFFFB923C);
  static const Color report = Color(0xFF818CF8);
  static const Color ai = Color(0xFF8B5CF6); // RYSE AI purple

  // AI / brand gradient (purple → indigo)
  static const List<Color> aiGradient = [Color(0xFF8B5CF6), Color(0xFF6366F1)];

  // Chart palette (dark-friendly)
  static const List<Color> chartPalette = [
    Color(0xFF8B5CF6),
    Color(0xFF60A5FA),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
    Color(0xFFFB7185),
    Color(0xFF818CF8),
    Color(0xFF2DD4BF),
  ];

  /// Stable avatar color derived from a name.
  static Color avatarColor(String seed) {
    const palette = [
      Color(0xFF8B5CF6),
      Color(0xFF6366F1),
      Color(0xFF0EA5E9),
      Color(0xFFF97316),
      Color(0xFFEC4899),
      Color(0xFF14B8A6),
      Color(0xFF84CC16),
    ];
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }
}
