import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';

/// Salesforce-style sales "Path": a horizontal chevron bar of stages.
/// Completed stages are dark green, the current stage is blue, upcoming
/// stages are grey. Tapping a stage selects it; the "Mark Stage as
/// Complete" button advances the deal.
class StagePath extends StatelessWidget {
  const StagePath({
    super.key,
    required this.currentStage,
    required this.onStageSelected,
  });

  final OpportunityStage currentStage;
  final ValueChanged<OpportunityStage> onStageSelected;

  @override
  Widget build(BuildContext context) {
    final stages = OpportunityStage.pathStages;
    final lost = currentStage == OpportunityStage.closedLost;
    final currentIndex =
        lost ? -1 : stages.indexOf(currentStage);

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stages.length,
        itemBuilder: (context, index) {
          final stage = stages[index];
          final Color color;
          final Color textColor;
          if (lost) {
            color = AppColors.border;
            textColor = AppColors.textSecondary;
          } else if (index < currentIndex ||
              currentStage == OpportunityStage.closedWon) {
            color = AppColors.success;
            textColor = Colors.white;
          } else if (index == currentIndex) {
            color = AppColors.brand;
            textColor = Colors.white;
          } else {
            color = AppColors.border;
            textColor = AppColors.textSecondary;
          }

          return GestureDetector(
            onTap: () => onStageSelected(stage),
            child: CustomPaint(
              painter: _ChevronPainter(
                color: color,
                isFirst: index == 0,
                isLast: index == stages.length - 1,
              ),
              child: Container(
                padding: EdgeInsets.only(
                  left: index == 0 ? 14 : 22,
                  right: 18,
                ),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    if (index < currentIndex ||
                        currentStage == OpportunityStage.closedWon) ...[
                      Icon(Icons.check, size: 13, color: textColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      stage.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({
    required this.color,
    required this.isFirst,
    required this.isLast,
  });

  final Color color;
  final bool isFirst;
  final bool isLast;

  static const double _tip = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isFirst) {
      path.moveTo(0, 0);
    } else {
      path.moveTo(0, 0);
    }
    path.lineTo(size.width - (isLast ? 0 : _tip), 0);
    if (!isLast) {
      path.lineTo(size.width, size.height / 2);
    }
    path.lineTo(size.width - (isLast ? 0 : _tip), size.height);
    path.lineTo(0, size.height);
    if (!isFirst) {
      path.lineTo(_tip, size.height / 2);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isFirst != isFirst ||
      oldDelegate.isLast != isLast;
}
