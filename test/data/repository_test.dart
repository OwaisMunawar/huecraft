import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:huecraft/features/studio/domain/color_value.dart';
import 'package:huecraft/features/studio/domain/palette.dart';
import '../support/fixture.dart';

void main() {
  test('SQLite seed, save, reopen and immutable history', () async {
    final dir = Directory.systemTemp.createTempSync('huecraft-test-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/palette.db';
    final repo = await repository(path: path);
    expect((await repo.load()).revision, 1);
    final changed = initialPalette.replacing(
      ColorRole.accent,
      ColorValue.parse('#375CDA'),
    );
    final saved = await repo.save(
      changed,
      expectedRevision: 1,
      note: 'Blue direction',
      at: DateTime.utc(2026),
    );
    expect(saved.revision, 2);
    expect((await repo.history()).map((r) => r.revision), [2, 1]);
    await expectLater(
      repo.database.rawUpdate(
        "UPDATE revisions SET note='overwrite' WHERE revision=1",
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      repo.database.rawDelete('DELETE FROM revisions WHERE revision=1'),
      throwsA(isA<Exception>()),
    );
    await repo.close();
    final reopened = await repository(path: path);
    expect((await reopened.load()).palette.toJson(), changed.toJson());
    expect((await reopened.history()).length, 2);
    await reopened.close();
  });
  test(
    'two concurrent stale saves produce one revision and typed rejection',
    () async {
      final repo = await repository();
      addTearDown(repo.close);
      final results = await Future.wait([
        for (var i = 0; i < 2; i++)
          repo
              .save(
                initialPalette,
                expectedRevision: 1,
                note: 'Reviewed $i',
                at: DateTime.utc(2026),
              )
              .then<Object>((value) => value)
              .catchError((Object e) => e),
      ]);
      expect(results.whereType<StudioFailure>().single.code, FailureCode.stale);
      expect((await repo.history()).length, 2);
      expect((await repo.load()).revision, 2);
    },
  );
  test(
    'invalid notes and forced transaction failures retain the old head',
    () async {
      final repo = await repository();
      addTearDown(repo.close);
      for (final note in ['x', 'a' * 121]) {
        await expectLater(
          repo.save(
            initialPalette,
            expectedRevision: 1,
            note: note,
            at: DateTime.utc(2026),
          ),
          throwsA(isA<StudioFailure>()),
        );
      }
      await repo.database.execute(
        "CREATE TRIGGER reject_head BEFORE UPDATE ON head BEGIN SELECT RAISE(ABORT, 'disk failure fixture'); END",
      );
      await expectLater(
        repo.save(
          initialPalette,
          expectedRevision: 1,
          note: 'Reviewed',
          at: DateTime.utc(2026),
        ),
        throwsA(
          isA<StudioFailure>().having(
            (e) => e.code,
            'code',
            FailureCode.storage,
          ),
        ),
      );
      expect((await repo.load()).revision, 1);
      expect((await repo.history()).length, 1);
    },
  );
  test('malformed persisted JSON fails without resetting user data', () async {
    final repo = await repository();
    addTearDown(repo.close);
    await repo.database.execute('DROP TRIGGER revisions_no_update');
    await repo.database.rawUpdate(
      "UPDATE revisions SET palette='broken' WHERE revision=1",
    );
    await expectLater(
      repo.load(),
      throwsA(
        isA<StudioFailure>().having((e) => e.code, 'code', FailureCode.storage),
      ),
    );
    expect((await repo.database.query('revisions')).length, 1);
  });
  test('closed storage reads return a typed failure', () async {
    final repo = await repository();
    await repo.close();
    await expectLater(
      repo.load(),
      throwsA(
        isA<StudioFailure>().having((e) => e.code, 'code', FailureCode.storage),
      ),
    );
    await expectLater(
      repo.history(),
      throwsA(
        isA<StudioFailure>().having((e) => e.code, 'code', FailureCode.storage),
      ),
    );
  });
}
