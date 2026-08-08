import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/ryse_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RyseAppTile(size: 84),
            const SizedBox(height: 22),
            const RyseWordmark(fontSize: 40),
            const SizedBox(height: 8),
            Text(
              'AI-DRIVEN CRM',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 44),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
