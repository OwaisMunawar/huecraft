import 'dart:async';
import '../domain/color_value.dart';
import '../domain/palette.dart';
import '../domain/ports.dart';
import '../domain/solver.dart';
import '../domain/token_report.dart';

final class ReviewedProposal {
  const ReviewedProposal(this.palette, this.origin, this.epoch);
  final Palette palette;
  final String origin;
  final int epoch;
}

final class StudioState {
  StudioState({
    required this.palette,
    this.revision = 1,
    Set<ColorRole> locks = const {},
    List<SavedRevision> history = const [],
    this.dirty = false,
    this.busy = false,
    this.modelAvailable = false,
    this.proposal,
    this.message,
  }) : locks = Set.unmodifiable(locks),
       history = List.unmodifiable(history);
  final Palette palette;
  final int revision;
  final Set<ColorRole> locks;
  final List<SavedRevision> history;
  final bool dirty;
  final bool busy;
  final bool modelAvailable;
  final ReviewedProposal? proposal;
  final String? message;
  StudioState copy({
    Palette? palette,
    int? revision,
    Set<ColorRole>? locks,
    List<SavedRevision>? history,
    bool? dirty,
    bool? busy,
    bool? modelAvailable,
    ReviewedProposal? proposal,
    String? message,
  }) => StudioState(
    palette: palette ?? this.palette,
    revision: revision ?? this.revision,
    locks: Set.unmodifiable(locks ?? this.locks),
    history: List.unmodifiable(history ?? this.history),
    dirty: dirty ?? this.dirty,
    busy: busy ?? this.busy,
    modelAvailable: modelAvailable ?? this.modelAvailable,
    proposal: proposal,
    message: message,
  );
}

final class StudioController {
  StudioController({
    required this.repository,
    required this.rules,
    required this.model,
    required this.now,
  });
  final PaletteRepository repository;
  final ProposalEngine rules;
  final ProposalEngine model;
  final DateTime Function() now;
  final _changes = StreamController<StudioState>.broadcast(sync: true);
  StudioState _state = StudioState(palette: initialPalette);
  int _epoch = 0;
  StudioState get state => _state;
  Stream<StudioState> get changes => _changes.stream;
  void _emit(StudioState value) {
    _state = value;
    _changes.add(value);
  }

  Future<void> initialize() async {
    final saved = await repository.load();
    _emit(
      _state.copy(
        palette: saved.palette,
        revision: saved.revision,
        history: await repository.history(),
        modelAvailable: await model.available(),
      ),
    );
  }

  void assign(ColorRole role, ColorValue color) {
    if (_state.locks.contains(role)) {
      throw const StudioFailure(
        FailureCode.invalidInput,
        'Unlock this role before editing it.',
      );
    }
    final palette = _state.palette.replacing(role, color);
    sampleCatalog.validate(palette);
    _epoch++;
    _emit(_state.copy(palette: palette, dirty: true));
  }

  void toggleLock(ColorRole role) {
    _epoch++;
    final locks = {..._state.locks};
    if (!locks.remove(role)) locks.add(role);
    _emit(_state.copy(locks: locks));
  }

  Future<void> propose(String brief, {required bool useModel}) async {
    if (_state.busy) return;
    final epoch = _epoch;
    final palette = _state.palette;
    final locks = _state.locks;
    _emit(_state.copy(busy: true));
    try {
      final options = proposalOptions(palette, sampleCatalog, locks);
      if (useModel && !_state.modelAvailable) {
        throw const StudioFailure(
          FailureCode.unavailable,
          'The on-device model is unavailable. Select Rules.',
        );
      }
      final engine = useModel ? model : rules;
      final index = await engine.choose(brief, options);
      if (_epoch != epoch) {
        throw const StudioFailure(
          FailureCode.stale,
          'The draft changed while the proposal ran. Request a new direction.',
        );
      }
      if (index < 0 || index >= options.length) {
        throw const StudioFailure(
          FailureCode.model,
          'The engine selected an invalid direction.',
        );
      }
      final result = options[index].palette;
      validateProposal(result, palette, sampleCatalog, locks);
      _emit(
        _state.copy(proposal: ReviewedProposal(result, engine.label, epoch)),
      );
    } on StudioFailure catch (error) {
      _emit(_state.copy(message: error.message));
    } finally {
      _emit(
        _state.copy(
          busy: false,
          proposal: _state.proposal,
          message: _state.message,
        ),
      );
    }
  }

  void repair() {
    try {
      final result = repairPalette(_state.palette, sampleCatalog, _state.locks);
      _emit(
        _state.copy(
          proposal: ReviewedProposal(
            result.palette,
            'Constraint solver · no model',
            _epoch,
          ),
          message: 'Review the minimum-change repair before applying.',
        ),
      );
    } on StudioFailure catch (error) {
      _emit(_state.copy(message: error.message));
    }
  }

  void applyProposal() {
    final proposal = _state.proposal;
    if (proposal == null || proposal.epoch != _epoch) {
      throw const StudioFailure(
        FailureCode.stale,
        'Request a current proposal first.',
      );
    }
    validateProposal(
      proposal.palette,
      _state.palette,
      sampleCatalog,
      _state.locks,
    );
    _epoch++;
    _emit(
      _state.copy(
        palette: proposal.palette,
        dirty: true,
        message: 'Applied to the draft. Save a revision when ready.',
      ),
    );
  }

  Future<void> save(String note) async {
    if (_state.busy || !_state.dirty) return;
    final epoch = _epoch;
    final palette = _state.palette;
    _emit(_state.copy(busy: true));
    try {
      final saved = await repository.save(
        palette,
        expectedRevision: _state.revision,
        note: note,
        at: now(),
      );
      final history = await repository.history();
      _emit(
        _state.copy(
          revision: saved.revision,
          dirty: _epoch != epoch,
          history: history,
          message: 'Revision ${saved.revision} saved on this device.',
        ),
      );
    } on StudioFailure catch (error) {
      _emit(_state.copy(message: error.message));
    } finally {
      _emit(_state.copy(busy: false, message: _state.message));
    }
  }

  void restore(SavedRevision revision) {
    if (_state.busy) return;
    _epoch++;
    _emit(
      _state.copy(
        palette: revision.palette,
        locks: const {},
        dirty: true,
        message:
            'Revision ${revision.revision} loaded as a draft. Save to create a new revision.',
      ),
    );
  }

  Future<void> reload() async {
    if (_state.busy) return;
    try {
      final saved = await repository.load();
      final history = await repository.history();
      _epoch++;
      _emit(
        _state.copy(
          palette: saved.palette,
          revision: saved.revision,
          dirty: false,
          history: history,
          locks: const {},
          message: 'Loaded the latest saved revision.',
        ),
      );
    } on StudioFailure catch (error) {
      _emit(_state.copy(message: error.message));
    }
  }

  String export({bool css = false}) {
    if (_state.dirty) {
      throw const StudioFailure(
        FailureCode.invalidInput,
        'Save the current draft before exporting.',
      );
    }
    return css
        ? cssReport(_state.palette, _state.revision)
        : tokenReport(_state.palette, _state.revision);
  }

  Future<void> close() async {
    await _changes.close();
    await repository.close();
  }
}
