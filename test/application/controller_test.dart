import 'dart:async';
import 'package:huecraft/features/studio/data/sqlite_palette_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huecraft/features/studio/domain/color_value.dart';
import 'package:huecraft/features/studio/domain/palette.dart';
import '../support/fixture.dart';

void main() {
  test(
    'propose does not change draft or history until review and save',
    () async {
      final c = await controller();
      addTearDown(c.close);
      final emissions = <bool>[];
      final sub = c.changes.listen((s) => emissions.add(s.busy));
      addTearDown(sub.cancel);
      await c.propose('A calm studio', useModel: false);
      expect(c.state.palette.toJson(), initialPalette.toJson());
      expect(c.state.history.length, 1);
      expect(c.state.proposal!.origin, 'Rules · no model');
      c.applyProposal();
      expect(c.state.dirty, isTrue);
      expect(() => c.export(), throwsA(isA<StudioFailure>()));
      await c.save('Reviewed direction');
      expect(c.state.revision, 2);
      expect(c.state.dirty, isFalse);
      expect(c.export(), contains('huecraft.tokens.v1'));
      expect(c.export(css: true), contains(':root'));
      expect(emissions, contains(true));
      await c.save('No change');
      expect(c.state.revision, 2);
    },
  );
  test('locks block edits and invalidate pending proposals', () async {
    final c = await controller();
    addTearDown(c.close);
    await c.propose('Calm studio', useModel: false);
    c.toggleLock(ColorRole.accent);
    expect(c.state.proposal, isNull);
    expect(
      () => c.assign(ColorRole.accent, sampleCatalog.colors.last),
      throwsA(isA<StudioFailure>()),
    );
    expect(() => c.applyProposal(), throwsA(isA<StudioFailure>()));
    c.toggleLock(ColorRole.accent);
    c.assign(ColorRole.accent, sampleCatalog.colors.last);
    c.repair();
    expect(c.state.proposal!.origin, 'Constraint solver · no model');
    c.applyProposal();
    expect(exportable(c.state.palette), isTrue);
  });
  test(
    'impossible repair remains a visible failure without mutation',
    () async {
      final c = await controller();
      addTearDown(c.close);
      c.assign(ColorRole.accent, sampleCatalog.colors.last);
      for (final role in ColorRole.values) {
        c.toggleLock(role);
      }
      c.repair();
      expect(c.state.proposal, isNull);
      expect(c.state.message, contains('No valid assignment'));
      expect(exportable(c.state.palette), isFalse);
    },
  );
  test(
    'restore creates a draft and a new save preserves old revisions',
    () async {
      final c = await controller();
      addTearDown(c.close);
      c.assign(ColorRole.accent, ColorValue.parse('#375CDA'));
      await c.save('Blue direction');
      c.restore(c.state.history.last);
      expect(c.state.dirty, isTrue);
      expect(c.state.revision, 2);
      await c.save('Restore the starter');
      expect(c.state.history.map((r) => r.revision), [3, 2, 1]);
      c.assign(ColorRole.accent, sampleCatalog.colors.last);
      await c.reload();
      expect(c.state.dirty, isFalse);
      expect(c.state.palette.toJson(), initialPalette.toJson());
    },
  );
  test(
    'stale database head and invalid notes do not discard the draft',
    () async {
      final c = await controller();
      addTearDown(c.close);
      c.assign(ColorRole.accent, sampleCatalog.colors.last);
      await c.save('x');
      expect(c.state.dirty, isTrue);
      expect(c.state.message, contains('3–120'));
      await c.repository.save(
        initialPalette,
        expectedRevision: 1,
        note: 'Another editor',
        at: DateTime.utc(2026),
      );
      await c.save('Our stale draft');
      expect(c.state.message, contains('newer palette'));
      expect(c.state.dirty, isTrue);
      await c.reload();
      expect(c.state.revision, 2);
    },
  );
  test(
    'model unavailable and invalid engine choices remain explicit',
    () async {
      final c = await controller();
      addTearDown(c.close);
      await c.propose('Calm studio', useModel: true);
      expect(c.state.message, contains('unavailable'));
      expect(c.state.proposal, isNull);
      final bad = await controller(model: Engine((_, _) async => 99));
      addTearDown(bad.close);
      await bad.propose('Calm studio', useModel: true);
      expect(bad.state.message, contains('invalid direction'));
      expect(bad.state.busy, isFalse);
    },
  );
  test(
    'late native results cannot overwrite a newer edit, and requests are single flight',
    () async {
      final completion = Completer<int>();
      var calls = 0;
      final c = await controller(
        model: Engine((_, _) {
          calls++;
          return completion.future;
        }),
      );
      addTearDown(c.close);
      final request = c.propose('Calm studio', useModel: true);
      await c.propose('Second request', useModel: true);
      await c.save('Busy save');
      c.restore(c.state.history.first);
      await c.reload();
      c.assign(ColorRole.accent, sampleCatalog.colors.last);
      completion.complete(0);
      await request;
      expect(calls, 1);
      expect(c.state.proposal, isNull);
      expect(c.state.palette[ColorRole.accent], sampleCatalog.colors.last);
      expect(c.state.message, contains('draft changed'));
    },
  );
  test(
    'valid native selection is labelled and still requires review',
    () async {
      final c = await controller(model: Engine((_, _) async => 0));
      addTearDown(c.close);
      await c.propose('A calm studio', useModel: true);
      expect(c.state.proposal!.origin, 'Injected test engine');
      expect(c.state.dirty, isFalse);
      expect(() => c.state.locks.add(ColorRole.ink), throwsUnsupportedError);
      expect(() => c.state.history.clear(), throwsUnsupportedError);
    },
  );
  test(
    'reload failures retain the draft and surface a storage message',
    () async {
      final c = await controller();
      addTearDown(c.close);
      c.assign(ColorRole.accent, sampleCatalog.colors.last);
      final db = (c.repository as SqlitePaletteRepository).database;
      await db.execute('DROP TRIGGER revisions_no_update');
      await db.rawUpdate(
        "UPDATE revisions SET palette='broken' WHERE revision=1",
      );
      await c.reload();
      expect(c.state.message, contains('could not be read'));
      expect(c.state.dirty, isTrue);
      expect(c.state.palette[ColorRole.accent], sampleCatalog.colors.last);
    },
  );
}
