import 'palette.dart';

final class SavedRevision {
  const SavedRevision({
    required this.revision,
    required this.palette,
    required this.note,
    required this.at,
  });
  final int revision;
  final Palette palette;
  final String note;
  final DateTime at;
}

abstract interface class PaletteRepository {
  Future<SavedRevision> load();
  Future<SavedRevision> save(
    Palette palette, {
    required int expectedRevision,
    required String note,
    required DateTime at,
  });
  Future<List<SavedRevision>> history();
  Future<void> close();
}

abstract interface class ProposalEngine {
  String get label;
  Future<bool> available();
  Future<int> choose(String brief, List<PaletteOption> options);
}
