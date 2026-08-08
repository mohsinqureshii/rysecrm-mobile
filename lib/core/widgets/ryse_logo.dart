import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The RYSE brand mark: a left-pointing triangle (apex on the left, vertical
/// edge on the right) filled with the brand purple gradient. Mirrors the mark
/// used across the RYSE web product.
class RyseMark extends StatelessWidget {
  const RyseMark({super.key, this.size = 28, this.gradient = true});

  final double size;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MarkPainter(gradient: gradient),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.gradient});

  final bool gradient;

  @override
  void paint(Canvas canvas, Size size) {
    // Scaled from the web mark path "M0 22 L44 0 L44 44 Z" (44×44 viewBox).
    final s = size.width / 44.0;
    final path = Path()
      ..moveTo(0, 22 * s)
      ..lineTo(44 * s, 0)
      ..lineTo(44 * s, 44 * s)
      ..close();
    final paint = Paint();
    if (gradient) {
      paint.shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: AppColors.aiGradient,
      ).createShader(Offset.zero & size);
    } else {
      paint.color = AppColors.brand;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      oldDelegate.gradient != gradient;
}

/// The full RYSE lockup: the "ryse" wordmark with the triangle mark tucked
/// against the final letter, exactly like the web logo.
class RyseWordmark extends StatelessWidget {
  const RyseWordmark({
    super.key,
    this.fontSize = 34,
    this.color,
  });

  final double fontSize;

  /// Ink for the wordmark text. Defaults to the theme's primary text color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? AppColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'ryse',
          style: TextStyle(
            color: ink,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
            height: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: fontSize * 0.06, bottom: fontSize * 0.18),
          child: RyseMark(size: fontSize * 0.6),
        ),
      ],
    );
  }
}

/// The mark inside a rounded "app tile", as used for the splash icon and the
/// app-store icon treatment (purple mark on a near-black rounded square).
class RyseAppTile extends StatelessWidget {
  const RyseAppTile({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.logoTile,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      alignment: Alignment.center,
      child: RyseMark(size: size * 0.5),
    );
  }
}
