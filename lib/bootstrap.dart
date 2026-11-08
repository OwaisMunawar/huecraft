import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'features/studio/application/studio_controller.dart';
import 'features/studio/data/proposal_engines.dart';
import 'features/studio/data/sqlite_palette_repository.dart';

Future<StudioController> openStudio({String? databasePath}) async {
  final database = await openDatabase(
    databasePath ?? path.join(await getDatabasesPath(), 'huecraft.db'),
    version: 1,
  );
  final repository = SqlitePaletteRepository(database);
  try {
    await repository.initialize();
    final controller = StudioController(
      repository: repository,
      rules: RulesProposalEngine(),
      model: const bool.fromEnvironment('DEMO')
          ? DisabledProposalEngine()
          : NativeProposalEngine(),
      now: DateTime.now,
    );
    await controller.initialize();
    return controller;
  } catch (_) {
    await repository.close();
    rethrow;
  }
}
