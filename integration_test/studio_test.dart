import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huecraft/app.dart';
import 'package:huecraft/bootstrap.dart';
import 'package:huecraft/features/studio/domain/palette.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

Future<void> checkpoint(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  if (const bool.fromEnvironment('CAPTURE_SCREENSHOTS')) {
    final directory = await getDatabasesPath();
    final ready = File(path.join(directory, 'huecraft-capture-$name.ready'));
    final ack = File('${ready.path}.ack');
    if (await ack.exists()) await ack.delete();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await ready.writeAsString('ready');
    debugPrint('HUECRAFT_SCREENSHOT:$name');
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (!await ack.exists()) {
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('Host did not acknowledge screenshot $name.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await ready.delete();
    await ack.delete();
  }
}

Future<void> tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native ranking, reviewed revisions, repair and export', (
    tester,
  ) async {
    final file = path.join(
      await getDatabasesPath(),
      'huecraft-verification.db',
    );
    await deleteDatabase(file);
    var c = await openStudio(databasePath: file);
    expect(
      c.state.modelAvailable,
      isTrue,
      reason: 'This verification requires the real Foundation Models adapter.',
    );
    await tester.pumpWidget(HuecraftApp(controller: c));
    await tester.pumpAndSettle();
    await checkpoint(tester, 'palette-studio');
    await tester.ensureVisible(find.byKey(const ValueKey('design-brief')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('design-brief')),
      'Choose a bold cobalt blue accent for a calm creative studio dashboard.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tap(tester, 'propose');
    expect(c.state.proposal, isNotNull, reason: c.state.message);
    expect(c.state.proposal!.origin, 'On-device AI');
    expect(c.state.dirty, isFalse);
    await tester.ensureVisible(find.byKey(const ValueKey('proposal-review')));
    await tester.pumpAndSettle();
    await checkpoint(tester, 'on-device-direction-review');
    await tap(tester, 'apply-proposal');
    await tap(tester, 'save-revision');
    expect(c.state.revision, 2);
    final saved = c.state.palette.toJson();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await c.close();
    c = await openStudio(databasePath: file);
    expect(c.state.revision, 2);
    expect(c.state.palette.toJson(), saved);
    await tester.pumpWidget(HuecraftApp(controller: c));
    await tester.pumpAndSettle();
    await tap(tester, 'role-accent');
    await tap(tester, 'swatch-#D4ED7B');
    for (final role in ColorRole.values.where((r) => r != ColorRole.accent)) {
      await tap(tester, 'lock-${role.name}');
    }
    await tap(tester, 'nav-audit');
    expect(exportable(c.state.palette), isFalse);
    await checkpoint(tester, 'failed-contrast-audit');
    await tap(tester, 'repair');
    expect(c.state.proposal, isNotNull);
    for (final role in c.state.locks) {
      expect(c.state.proposal!.palette[role], c.state.palette[role]);
    }
    await tester.ensureVisible(find.byKey(const ValueKey('proposal-review')));
    await tester.pumpAndSettle();
    await checkpoint(tester, 'minimum-change-repair-review');
    await tap(tester, 'apply-proposal');
    expect(exportable(c.state.palette), isTrue);
    await tap(tester, 'nav-studio');
    await tap(tester, 'save-revision');
    expect(c.state.revision, 3);
    await tap(tester, 'nav-library');
    await checkpoint(tester, 'saved-revision-library');
    await tap(tester, 'export-json');
    expect(find.textContaining('huecraft.tokens.v1'), findsOneWidget);
    expect(c.export(), contains('"revision": 3'));
    await checkpoint(tester, 'verified-token-export');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await c.close();
    await deleteDatabase(file);
  });
}
