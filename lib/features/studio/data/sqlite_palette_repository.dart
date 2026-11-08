import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../domain/color_value.dart';
import '../domain/palette.dart';
import '../domain/ports.dart';

final class SqlitePaletteRepository implements PaletteRepository {
  SqlitePaletteRepository(this.database);
  final Database database;
  Future<void> initialize() async {
    await database.execute('PRAGMA foreign_keys=ON');
    await database.transaction((txn) async {
      await txn.execute(
        'CREATE TABLE IF NOT EXISTS revisions (revision INTEGER PRIMARY KEY, palette TEXT NOT NULL, note TEXT NOT NULL, created_at TEXT NOT NULL)',
      );
      await txn.execute(
        'CREATE TABLE IF NOT EXISTS head (id INTEGER PRIMARY KEY CHECK(id=1), revision INTEGER NOT NULL REFERENCES revisions(revision))',
      );
      await txn.execute(
        "CREATE TRIGGER IF NOT EXISTS revisions_no_update BEFORE UPDATE ON revisions BEGIN SELECT RAISE(ABORT, 'immutable revision'); END",
      );
      await txn.execute(
        "CREATE TRIGGER IF NOT EXISTS revisions_no_delete BEFORE DELETE ON revisions BEGIN SELECT RAISE(ABORT, 'immutable revision'); END",
      );
      if ((await txn.query('head')).isEmpty) {
        await txn.insert('revisions', {
          'revision': 1,
          'palette': jsonEncode(initialPalette.toJson()),
          'note': 'Starter palette',
          'created_at': '2026-01-01T00:00:00.000Z',
        });
        await txn.insert('head', {'id': 1, 'revision': 1});
      }
    });
  }

  SavedRevision _decode(Map<String, Object?> row) {
    final revision = row['revision'];
    final palette = row['palette'];
    final note = row['note'];
    final at = row['created_at'];
    if (revision is! int ||
        revision < 1 ||
        palette is! String ||
        note is! String ||
        at is! String) {
      throw const StudioFailure(
        FailureCode.storage,
        'The saved palette could not be read. No data was reset.',
      );
    }
    try {
      return SavedRevision(
        revision: revision,
        palette: Palette.fromJson(jsonDecode(palette)),
        note: note,
        at: DateTime.parse(at),
      );
    } on FormatException {
      throw const StudioFailure(
        FailureCode.storage,
        'The saved palette is malformed. No data was reset.',
      );
    }
  }

  @override
  Future<SavedRevision> load() async {
    final rows = await database.rawQuery(
      'SELECT r.* FROM revisions r JOIN head h ON h.revision=r.revision WHERE h.id=1',
    );
    if (rows.length != 1) {
      throw const StudioFailure(
        FailureCode.storage,
        'The palette head is missing.',
      );
    }
    return _decode(rows.single);
  }

  @override
  Future<SavedRevision> save(
    Palette palette, {
    required int expectedRevision,
    required String note,
    required DateTime at,
  }) async {
    sampleCatalog.validate(palette);
    if (note.trim().length < 3 || note.length > 120 || expectedRevision < 1) {
      throw const StudioFailure(
        FailureCode.invalidInput,
        'Use a revision note of 3–120 characters.',
      );
    }
    try {
      return await database.transaction((txn) async {
        final head = (await txn.query(
          'head',
          where: 'id=1',
        )).single['revision'];
        if (head != expectedRevision) {
          throw const StudioFailure(
            FailureCode.stale,
            'A newer palette was saved. Reload before saving.',
          );
        }
        final next = expectedRevision + 1;
        await txn.insert('revisions', {
          'revision': next,
          'palette': jsonEncode(palette.toJson()),
          'note': note.trim(),
          'created_at': at.toUtc().toIso8601String(),
        });
        final updated = await txn.update(
          'head',
          {'revision': next},
          where: 'id=1 AND revision=?',
          whereArgs: [expectedRevision],
        );
        if (updated != 1) {
          throw const StudioFailure(
            FailureCode.stale,
            'The palette changed while saving.',
          );
        }
        return SavedRevision(
          revision: next,
          palette: palette,
          note: note.trim(),
          at: at.toUtc(),
        );
      });
    } on DatabaseException {
      throw const StudioFailure(
        FailureCode.storage,
        'The palette could not be saved. Try again; existing revisions are retained.',
      );
    }
  }

  @override
  Future<List<SavedRevision>> history() async => (await database.query(
    'revisions',
    orderBy: 'revision DESC',
  )).map(_decode).toList(growable: false);
  @override
  Future<void> close() => database.close();
}
