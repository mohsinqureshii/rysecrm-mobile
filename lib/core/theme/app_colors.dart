import 'package:flutter/material.dart';

/// Design tokens — a clean, light design system (white surfaces, near-black
/// primary actions, soft borders), matching the Symt product aesthetic.
class AppColors {
  AppColors._();

  // Primary action — near-black (buttons, selected states, key CTAs)
  static const Color ink = Color(0xFF0B0B0F);
  static const Color inkSoft = Color(0xFF1C1C22);

  /// `brand` is kept as an alias so existing call-sites resolve; the primary
  /// interactive color is near-black, Symt-style.
  static const Color brand = ink;
  static const Color brandStrong = Color(0xFF000000);
  static const Color brandDark = Color(0xFF000000);

  // Purple is retained only as the AI accent (RYSE AI / assistant highlights).
  static const Color accent = Color(0xFF7C3AED);
  static const Color accentSoft = Color(0xFFEDE9FE);
  static const Color brandAccent = Color(0xFF7C3AED);

  // Surfaces (white / near-white)
  static const Color background = Color(0xFFFFFFFF); // scaffold
  static const Color surface = Color(0xFFFFFFFF); // cards
  static const Color surfaceAlt = Color(0xFFF4F5F7); // inputs / raised chips
  static const Color header = Color(0xFFFFFFFF); // app bars
  static const Color canvas = Color(0xFFF7F8FA); // page wash behind cards
  static const Color logoTile = Color(0xFF0B0B0F);
  static const Color border = Color(0xFFE8E9ED);
  static const Color borderStrong = Color(0xFFD7D9E0);

  // Soft neutral wash (avatars, subtle fills)
  static const Color cloud = Color(0xFFF1F2F5);

  // Text
  static const Color textPrimary = Color(0xFF0B0B0F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9AA0AC);
  static const Color textOnDark = Colors.white;

  // Semantic
  static const Color success = Color(0xFF178A5A);
  static const Color successLight = Color(0xFFE6F5EE);
  static const Color error = Color(0xFFD64545);
  static const Color errorBright = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFCEBEB);
  static const Color warning = Color(0xFFB45309);
  static const Color warningDark = Color(0xFF92400E);
  static const Color warningLight = Color(0xFFFDF3E7);
  static const Color info = Color(0xFF6B7280);

  // Record-type colors (Symt-style dotted category palette)
  static const Color lead = Color(0xFFEF5DA8); // pink
  static const Color contact = Color(0xFF7C3AED); // violet
  static const Color account = Color(0xFF2563EB); // blue
  static const Color opportunity = Color(0xFFF59E0B); // amber
  static const Color task = Color(0xFF17A34A); // green
  static const Color event = Color(0xFFEC4899); // magenta
  static const Color campaign = Color(0xFFF97316); // orange
  static const Color report = Color(0xFF6366F1); // indigo
  static const Color ai = Color(0xFF7C3AED); // AI purple

  // AI / brand gradient (purple → indigo) — used only for AI surfaces
  static const List<Color> aiGradient = [Color(0xFF7C3AED), Color(0xFF6366F1)];

  // Chart palette
  static const List<Color> chartPalette = [
    Color(0xFF2563EB),
    Color(0xFF17A34A),
    Color(0xFFF59E0B),
    Color(0xFFEF5DA8),
    Color(0xFF7C3AED),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
  ];

  /// Stable avatar color derived from a name.
  static Color avatarColor(String seed) {
    const palette = [
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
      Color(0xFF0EA5E9),
      Color(0xFFF97316),
      Color(0xFFEC4899),
      Color(0xFF14B8A6),
      Color(0xFF16A34A),
    ];
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }
}
