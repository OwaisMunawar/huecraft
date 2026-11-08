import 'color_value.dart';
import 'palette.dart';

final class SolveResult {
  const SolveResult(this.palette, this.visited);
  final Palette palette;
  final int visited;
}

SolveResult repairPalette(
  Palette start,
  PaletteCatalog catalog,
  Set<ColorRole> locked, {
  int maxNodes = 150000,
}) {
  catalog.validate(start);
  if (maxNodes < 1) {
    throw const StudioFailure(
      FailureCode.budget,
      'Search budget must be positive.',
    );
  }
  // One changed role always costs more than every possible RGB-distance tie breaker.
  const changeCost = 2000000;
  var bestCost = 1 << 62;
  Palette? best;
  var visited = 0;
  final assigned = <ColorRole, ColorValue>{};
  void search(int depth, int cost) {
    if (++visited > maxNodes) {
      throw const StudioFailure(
        FailureCode.budget,
        'Search limit reached. Lock fewer roles or use fewer colors.',
      );
    }
    if (cost >= bestCost) return;
    if (depth == ColorRole.values.length) {
      best = Palette(assigned);
      bestCost = cost;
      return;
    }
    final role = ColorRole.values[depth];
    final choices = locked.contains(role)
        ? [start[role]]
        : [
            start[role],
            ...catalog.colors.where((color) => color != start[role]).toList()
              ..sort((a, b) => a.rgb.compareTo(b.rgb)),
          ];
    for (final color in choices) {
      assigned[role] = color;
      final passes = requiredPairs.every(
        (rule) =>
            !assigned.containsKey(rule.foreground) ||
            !assigned.containsKey(rule.background) ||
            assigned[rule.foreground]!.contrast(assigned[rule.background]!) >=
                rule.minimum,
      );
      if (passes) {
        search(
          depth + 1,
          cost +
              (color == start[role]
                  ? 0
                  : changeCost + color.distance(start[role])),
        );
      }
    }
    assigned.remove(role);
  }

  search(0, 0);
  if (best == null) {
    throw const StudioFailure(
      FailureCode.impossible,
      'No valid assignment preserves these locks. Unlock a role and try again.',
    );
  }
  return SolveResult(best!, visited);
}

List<PaletteOption> proposalOptions(
  Palette start,
  PaletteCatalog catalog,
  Set<ColorRole> locked,
) {
  final options = <PaletteOption>[];
  final seen = <String>{};
  final accents = locked.contains(ColorRole.accent)
      ? [start[ColorRole.accent]]
      : catalog.colors;
  for (final accent in accents) {
    try {
      final palette = repairPalette(
        start.replacing(ColorRole.accent, accent),
        catalog,
        {...locked, ColorRole.accent},
      ).palette;
      final signature = palette.toJson().values.join();
      if (seen.add(signature)) {
        options.add(PaletteOption('Direction ${options.length + 1}', palette));
      }
      if (options.length == 3) break;
    } on StudioFailure catch (error) {
      if (error.code != FailureCode.impossible) rethrow;
    }
  }
  if (options.isEmpty) {
    throw const StudioFailure(
      FailureCode.impossible,
      'No valid proposal preserves these locks.',
    );
  }
  return List.unmodifiable(options);
}

void validateProposal(
  Palette proposal,
  Palette current,
  PaletteCatalog catalog,
  Set<ColorRole> locks,
) {
  catalog.validate(proposal);
  if (!exportable(proposal) ||
      locks.any((role) => proposal[role] != current[role])) {
    throw const StudioFailure(
      FailureCode.model,
      'The proposal failed contrast or lock validation.',
    );
  }
}
