import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huecraft/app.dart';
import 'package:huecraft/features/studio/domain/palette.dart';
import 'support/fixture.dart';

void main() {
  testWidgets('rules proposal requires review and save before export', (
    tester,
  ) async {
    final c = await controller(memory: true);
    await tester.pumpWidget(HuecraftApp(controller: c));
    await tester.pumpAndSettle();
    final propose = find.byKey(const ValueKey('propose'));
    await tester.ensureVisible(propose);
    await tester.pumpAndSettle();
    await tester.tap(propose);
    await tester.pumpAndSettle();
    expect(c.state.dirty, isFalse);
    expect(c.state.proposal!.origin, 'Rules · no model');
    final apply = find.byKey(const ValueKey('apply-proposal'));
    await tester.ensureVisible(apply);
    await tester.pumpAndSettle();
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(c.state.dirty, isTrue);
    final save = find.byKey(const ValueKey('save-revision'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(c.state.revision, 2);
    await tester.tap(find.byKey(const ValueKey('nav-library')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('export-json')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-json')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('export-content')), findsOneWidget);
    expect(find.textContaining('huecraft.tokens.v1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await c.close();
  });
  testWidgets('failed palette blocks export and exposes a reviewed repair', (
    tester,
  ) async {
    final c = await controller(memory: true);
    c.assign(ColorRole.accent, sampleCatalog.colors.last);
    await tester.pumpWidget(HuecraftApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-library')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('export-json')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('nav-audit')));
    await tester.pumpAndSettle();
    expect(find.text('3 PAIRS NEED ATTENTION'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('repair')));
    await tester.tap(find.byKey(const ValueKey('repair')));
    await tester.pumpAndSettle();
    expect(c.state.proposal, isNotNull);
    expect(exportable(c.state.palette), isFalse);
    await tester.ensureVisible(find.byKey(const ValueKey('apply-proposal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('apply-proposal')));
    await tester.pumpAndSettle();
    expect(exportable(c.state.palette), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await c.close();
  });
  testWidgets('swatch selection and lock controls enforce the same roles', (
    tester,
  ) async {
    final c = await controller(memory: true);
    await tester.pumpWidget(HuecraftApp(controller: c));
    await tester.pumpAndSettle();
    final role = find.byKey(const ValueKey('role-accent'));
    await tester.ensureVisible(role);
    await tester.pumpAndSettle();
    await tester.tap(role);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('swatch-#375CDA')));
    await tester.pumpAndSettle();
    expect(c.state.palette[ColorRole.accent].hex, '#375CDA');
    await tester.tap(find.byKey(const ValueKey('lock-accent')));
    await tester.pumpAndSettle();
    expect(c.state.locks, contains(ColorRole.accent));
    expect(tester.widget<ListTile>(role).enabled, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await c.close();
  });
  testWidgets('all three pages lay out at narrow width and 2x text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 1000));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = await controller(memory: true);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: HuecraftApp(controller: c),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      MediaQuery.textScalerOf(tester.element(find.text('huecraft'))).scale(10),
      20,
    );
    for (final tab in ['nav-audit', 'nav-library', 'nav-studio']) {
      await tester.tap(find.byKey(ValueKey(tab)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await c.close();
  });
}
