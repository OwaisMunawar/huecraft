import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:huecraft/features/studio/domain/color_value.dart';
import 'package:huecraft/features/studio/domain/palette.dart';
import 'package:huecraft/features/studio/domain/solver.dart';
import 'package:huecraft/features/studio/domain/token_report.dart';

void main() {
  final black = ColorValue.parse('#000000');
  final white = ColorValue.parse('#FFFFFF');
  test('hex parsing is normalized, opaque and value-equal', () {
    expect(ColorValue.parse(' aBc123 ').hex, '#ABC123');
    expect(ColorValue.parse('000000'), black);
    expect(ColorValue.parse('000000').hashCode, black.hashCode);
    expect(ColorValue.parse('FF0080').red, 255);
    expect(ColorValue.parse('FF0080').green, 0);
    expect(ColorValue.parse('FF0080').blue, 128);
    expect(black.distance(white), 195075);
    expect(black.toString(), isNotEmpty);
    for (final value in [
      '',
      '#FFF',
      '#FFFFFFFF',
      '-123456',
      '#GG0000',
      '#123456;',
    ]) {
      expect(() => ColorValue.parse(value), throwsA(isA<StudioFailure>()));
    }
    expect(
      const StudioFailure(FailureCode.invalidInput, 'Exact error').toString(),
      'Exact error',
    );
  });
  test('W3C reference endpoints and published sample are exact', () {
    expect(black.luminance, 0);
    expect(white.luminance, closeTo(1, 1e-12));
    expect(black.contrast(white), 21);
    expect(white.contrast(white), 1);
    expect(
      ColorValue.parse('#777777').contrast(white),
      closeTo(4.478089453577214, 1e-12),
    );
    expect(
      const PairRule(ColorRole.ink, ColorRole.surface, 4.5, 'Text').passes(
        initialPalette.replacing(ColorRole.ink, ColorValue.parse('#777777')),
      ),
      isFalse,
    );
    expect(ColorValue.parse('#767676').contrast(white), greaterThan(4.5));
  });
  test(
    'contrast symmetry, bounds and scale hold across random opaque colors',
    () {
      final random = Random(20261108);
      for (var i = 0; i < 500; i++) {
        final a = ColorValue.parse(
          random.nextInt(1 << 24).toRadixString(16).padLeft(6, '0'),
        );
        final b = ColorValue.parse(
          random.nextInt(1 << 24).toRadixString(16).padLeft(6, '0'),
        );
        expect(a.contrast(b), inInclusiveRange(1, 21));
        expect(a.contrast(b), b.contrast(a));
        expect(a.contrast(a), 1);
        expect(a.luminance, inInclusiveRange(0, 1));
      }
    },
  );
  test('all roles serialize strictly and defensively', () {
    final json = initialPalette.toJson();
    expect(Palette.fromJson(json).toJson(), json);
    expect(() => initialPalette.colors.clear(), throwsUnsupportedError);
    expect(() => Palette({}), throwsA(isA<StudioFailure>()));
    for (final value in [
      null,
      <String, Object?>{},
      {...json, 'extra': '#000000'},
      {...json, 'ink': 1},
    ]) {
      expect(() => Palette.fromJson(value), throwsA(isA<StudioFailure>()));
    }
    expect(ColorRole.values.map((r) => r.label).toSet().length, 6);
    expect(requiredPairs.first.label, 'Primary text / Canvas');
    expect(exportable(initialPalette), isTrue);
  });
  test('catalog validates uniqueness, bounds and membership', () {
    expect(() => PaletteCatalog([white]), throwsA(isA<StudioFailure>()));
    expect(() => PaletteCatalog([white, white]), throwsA(isA<StudioFailure>()));
    expect(
      () => PaletteCatalog(
        List.generate(
          13,
          (i) => ColorValue.parse(i.toRadixString(16).padLeft(6, '0')),
        ),
      ),
      throwsA(isA<StudioFailure>()),
    );
    expect(() => sampleCatalog.colors.clear(), throwsUnsupportedError);
    expect(
      () => sampleCatalog.validate(
        initialPalette.replacing(ColorRole.accent, black),
      ),
      throwsA(isA<StudioFailure>()),
    );
  });
  test('solver leaves an already-valid palette unchanged', () {
    final result = repairPalette(initialPalette, sampleCatalog, {});
    expect(result.palette.toJson(), initialPalette.toJson());
    expect(result.visited, greaterThan(0));
  });
  test('repair changes only one role and preserves all locks', () {
    final broken = initialPalette.replacing(
      ColorRole.accent,
      ColorValue.parse('#D4ED7B'),
    );
    final locks = ColorRole.values.where((r) => r != ColorRole.accent).toSet();
    final result = repairPalette(broken, sampleCatalog, locks);
    expect(exportable(result.palette), isTrue);
    expect(
      ColorRole.values.where((r) => broken[r] != result.palette[r]).toList(),
      [ColorRole.accent],
    );
    expect(
      repairPalette(broken, sampleCatalog, locks).palette.toJson(),
      result.palette.toJson(),
    );
  });
  test('unsatisfiable locks never unlock or mutate the input', () {
    final broken = initialPalette.replacing(
      ColorRole.accent,
      ColorValue.parse('#D4ED7B'),
    );
    final before = broken.toJson();
    expect(
      () => repairPalette(broken, sampleCatalog, ColorRole.values.toSet()),
      throwsA(
        isA<StudioFailure>().having(
          (e) => e.code,
          'code',
          FailureCode.impossible,
        ),
      ),
    );
    expect(broken.toJson(), before);
    for (final budget in [0, 1]) {
      expect(
        () =>
            repairPalette(initialPalette, sampleCatalog, {}, maxNodes: budget),
        throwsA(
          isA<StudioFailure>().having(
            (e) => e.code,
            'code',
            FailureCode.budget,
          ),
        ),
      );
    }
  });
  test('proposal catalog is valid, deduplicated and respects locked roles', () {
    final options = proposalOptions(initialPalette, sampleCatalog, {
      ColorRole.canvas,
    });
    expect(options.length, inInclusiveRange(1, 3));
    expect(
      options.map((o) => o.palette.toJson().toString()).toSet().length,
      options.length,
    );
    for (final option in options) {
      expect(option.title, startsWith('Direction'));
      expect(
        option.palette[ColorRole.canvas],
        initialPalette[ColorRole.canvas],
      );
      validateProposal(option.palette, initialPalette, sampleCatalog, {
        ColorRole.canvas,
      });
    }
    expect(
      proposalOptions(
        initialPalette,
        sampleCatalog,
        ColorRole.values.toSet(),
      ).length,
      1,
    );
    final broken = initialPalette.replacing(
      ColorRole.accent,
      ColorValue.parse('#D4ED7B'),
    );
    expect(
      () => proposalOptions(broken, sampleCatalog, ColorRole.values.toSet()),
      throwsA(isA<StudioFailure>()),
    );
    expect(
      () => validateProposal(broken, initialPalette, sampleCatalog, {}),
      throwsA(isA<StudioFailure>()),
    );
    final changed = initialPalette.replacing(
      ColorRole.accent,
      ColorValue.parse('#375CDA'),
    );
    expect(
      () => validateProposal(changed, initialPalette, sampleCatalog, {
        ColorRole.accent,
      }),
      throwsA(isA<StudioFailure>()),
    );
  });
  test(
    'export contains exact checks and refuses failed or unsaved palettes',
    () {
      final decoded =
          jsonDecode(tokenReport(initialPalette, 4)) as Map<String, Object?>;
      expect(decoded['revision'], 4);
      expect(decoded['tokens'], initialPalette.toJson());
      expect((decoded['checks']! as List<Object?>).length, 7);
      expect(cssReport(initialPalette, 4), contains('--on-accent: #FFFFFF;'));
      expect(cssReport(initialPalette, 4), startsWith(':root {\n'));
      expect(
        () => tokenReport(initialPalette, 0),
        throwsA(isA<StudioFailure>()),
      );
      expect(
        () => tokenReport(initialPalette.replacing(ColorRole.ink, white), 2),
        throwsA(isA<StudioFailure>()),
      );
    },
  );
  test('all single-role perturbations admit a lock-preserving repair', () {
    for (final role in ColorRole.values) {
      for (final color in sampleCatalog.colors) {
        final changed = initialPalette.replacing(role, color);
        final result = repairPalette(
          changed,
          sampleCatalog,
          ColorRole.values.where((r) => r != role).toSet(),
        );
        expect(exportable(result.palette), isTrue);
        expect(
          ColorRole.values.where((r) => result.palette[r] != changed[r]).length,
          lessThanOrEqualTo(1),
        );
      }
    }
  });
  test('solver optimum agrees with an exhaustive two-color oracle', () {
    final colors = [black, white];
    final catalog = PaletteCatalog(colors);
    Palette fromBits(int bits) => Palette({
      for (var i = 0; i < 6; i++) ColorRole.values[i]: colors[(bits >> i) & 1],
    });
    final valid = [
      for (var i = 0; i < 64; i++) fromBits(i),
    ].where(exportable).toList();
    for (var bits = 0; bits < 64; bits++) {
      final start = fromBits(bits);
      int cost(Palette p) => ColorRole.values.fold(
        0,
        (sum, r) =>
            sum + (p[r] == start[r] ? 0 : 2000000 + p[r].distance(start[r])),
      );
      final expected = valid.map(cost).reduce(min);
      expect(cost(repairPalette(start, catalog, {}).palette), expected);
    }
  });
}
