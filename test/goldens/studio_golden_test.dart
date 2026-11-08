@Tags(['golden'])
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huecraft/app.dart';
import 'package:huecraft/features/studio/domain/palette.dart';
import '../support/fixture.dart';

class TolerantComparator extends LocalFileComparator {
  TolerantComparator(super.testFile);
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final passed = result.passed || result.diffPercent <= .005;
    if (!passed) {
      final output = await generateFailureOutput(result, golden, basedir);
      result.dispose();
      throw FlutterError(output);
    }
    result.dispose();
    return true;
  }
}

void main() {
  setUpAll(
    () => goldenFileComparator = TolerantComparator(
      Uri.file(
        '${Directory.current.path}/test/goldens/studio_golden_test.dart',
      ),
    ),
  );
  for (final tab in ['studio', 'audit', 'library']) {
    testWidgets('$tab layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = await controller(memory: true);
      if (tab == 'audit') c.assign(ColorRole.accent, sampleCatalog.colors.last);
      await tester.pumpWidget(HuecraftApp(controller: c));
      await tester.pumpAndSettle();
      if (tab != 'studio') {
        await tester.tap(find.byKey(ValueKey('nav-$tab')));
        await tester.pumpAndSettle();
      }
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('$tab.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await c.close();
    });
  }
}
