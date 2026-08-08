// Renders the RYSE app-icon masters as PNGs using the Flutter rasterizer.
//
//   flutter test test/tools/generate_icons_test.dart --update-goldens
//
// Produces:
//   test/tools/branding/app_icon.png            1024² opaque (iOS + legacy)
//   test/tools/branding/app_icon_foreground.png 1024² transparent, safe-zone
//                                               centered mark (Android adaptive)
//
// These are copied into assets/branding/ and fed to flutter_launcher_icons.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryse_crm/core/theme/app_colors.dart';
import 'package:ryse_crm/core/widgets/ryse_logo.dart';

Future<void> _render(WidgetTester tester, String name, Widget child) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1024, 1024);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(width: 1024, height: 1024, child: child),
    ),
  );
  await expectLater(
    find.byType(SizedBox).first,
    matchesGoldenFile('branding/$name.png'),
  );
}

void main() {
  testWidgets('app_icon (opaque, full-bleed)', (tester) async {
    await _render(
      tester,
      'app_icon',
      Container(
        color: AppColors.logoTile, // deep navy #0F1729
        alignment: Alignment.center,
        child: const RyseMark(size: 560),
      ),
    );
  });

  testWidgets('app_icon_foreground (transparent, safe zone)', (tester) async {
    await _render(
      tester,
      'app_icon_foreground',
      const Center(child: RyseMark(size: 440)),
    );
  });
}
