import 'package:huecraft/features/studio/application/studio_controller.dart';
import 'package:huecraft/features/studio/data/proposal_engines.dart';
import 'package:huecraft/features/studio/data/sqlite_palette_repository.dart';
import 'package:huecraft/features/studio/domain/palette.dart';
import 'package:huecraft/features/studio/domain/ports.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<SqlitePaletteRepository> repository({
  String path = inMemoryDatabasePath,
}) async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  final repo = SqlitePaletteRepository(db);
  await repo.initialize();
  return repo;
}

Future<StudioController> controller({
  ProposalEngine? model,
  bool memory = false,
}) async {
  final result = StudioController(
    repository: memory ? MemoryRepository() : await repository(),
    rules: RulesProposalEngine(),
    model: model ?? DisabledProposalEngine(),
    now: () => DateTime.utc(2026, 11, 8, 9, 41),
  );
  await result.initialize();
  return result;
}

final class Engine implements ProposalEngine {
  Engine(this.callback, {this.enabled = true});
  final Future<int> Function(String, List<PaletteOption>) callback;
  final bool enabled;
  @override
  String get label => 'Injected test engine';
  @override
  Future<bool> available() async => enabled;
  @override
  Future<int> choose(String brief, List<PaletteOption> options) =>
      callback(brief, options);
}

final class MemoryRepository implements PaletteRepository {
  final revisions = <SavedRevision>[
    SavedRevision(
      revision: 1,
      palette: initialPalette,
      note: 'Starter palette',
      at: DateTime.utc(2026),
    ),
  ];
  @override
  Future<SavedRevision> load() async => revisions.last;
  @override
  Future<List<SavedRevision>> history() async => revisions.reversed.toList();
  @override
  Future<SavedRevision> save(
    Palette palette, {
    required int expectedRevision,
    required String note,
    required DateTime at,
  }) async {
    final saved = SavedRevision(
      revision: expectedRevision + 1,
      palette: palette,
      note: note,
      at: at,
    );
    revisions.add(saved);
    return saved;
  }

  @override
  Future<void> close() async {}
}
