import 'color_value.dart';

enum ColorRole { canvas, surface, ink, muted, accent, onAccent }

extension RoleLabel on ColorRole {
  String get label => switch (this) {
    ColorRole.canvas => 'Canvas',
    ColorRole.surface => 'Surface',
    ColorRole.ink => 'Primary text',
    ColorRole.muted => 'Secondary text',
    ColorRole.accent => 'Accent',
    ColorRole.onAccent => 'On accent',
  };
}

final class Palette {
  Palette(Map<ColorRole, ColorValue> colors)
    : colors = Map.unmodifiable(colors) {
    if (colors.length != ColorRole.values.length ||
        !ColorRole.values.every(colors.containsKey)) {
      throw const StudioFailure(
        FailureCode.invalidInput,
        'Assign all six color roles.',
      );
    }
  }
  final Map<ColorRole, ColorValue> colors;
  ColorValue operator [](ColorRole role) => colors[role]!;
  Palette replacing(ColorRole role, ColorValue color) =>
      Palette({...colors, role: color});
  Map<String, String> toJson() => {
    for (final role in ColorRole.values) role.name: this[role].hex,
  };
  factory Palette.fromJson(Object? value) {
    if (value is! Map<String, Object?> || value.length != 6) {
      throw const StudioFailure(
        FailureCode.invalidInput,
        'Invalid palette snapshot.',
      );
    }
    return Palette({
      for (final role in ColorRole.values)
        role: ColorValue.parse(_text(value[role.name])),
    });
  }
  static String _text(Object? value) {
    if (value is! String) {
      throw const StudioFailure(
        FailureCode.invalidInput,
        'A color must be a hex string.',
      );
    }
    return value;
  }
}

final class PairRule {
  const PairRule(this.foreground, this.background, this.minimum, this.usage);
  final ColorRole foreground;
  final ColorRole background;
  final double minimum;
  final String usage;
  String get label => '${foreground.label} / ${background.label}';
  bool passes(Palette palette) => ratio(palette) >= minimum;
  double ratio(Palette palette) =>
      palette[foreground].contrast(palette[background]);
}

const requiredPairs = [
  PairRule(ColorRole.ink, ColorRole.canvas, 4.5, 'Normal text'),
  PairRule(ColorRole.ink, ColorRole.surface, 4.5, 'Normal text'),
  PairRule(ColorRole.muted, ColorRole.canvas, 4.5, 'Normal text'),
  PairRule(ColorRole.muted, ColorRole.surface, 4.5, 'Normal text'),
  PairRule(ColorRole.onAccent, ColorRole.accent, 4.5, 'Button text'),
  PairRule(ColorRole.accent, ColorRole.canvas, 3, 'Control boundary'),
  PairRule(ColorRole.accent, ColorRole.surface, 3, 'Control boundary'),
];

bool exportable(Palette palette) =>
    requiredPairs.every((rule) => rule.passes(palette));

final class PaletteCatalog {
  PaletteCatalog(Iterable<ColorValue> values)
    : colors = List.unmodifiable(values) {
    if (colors.length < 2 ||
        colors.length > 12 ||
        colors.toSet().length != colors.length) {
      throw const StudioFailure(
        FailureCode.invalidInput,
        'Use 2–12 unique opaque colors.',
      );
    }
  }
  final List<ColorValue> colors;
  void validate(Palette palette) {
    if (palette.colors.values.any((color) => !colors.contains(color))) {
      throw const StudioFailure(
        FailureCode.invalidInput,
        'A role uses a color outside this catalog.',
      );
    }
  }
}

final class PaletteOption {
  const PaletteOption(this.title, this.palette);
  final String title;
  final Palette palette;
}

final sampleCatalog = PaletteCatalog(
  [
    '#F6F5EF',
    '#FFFFFF',
    '#172A28',
    '#56635E',
    '#166B5C',
    '#375CDA',
    '#8C3F69',
    '#D4ED7B',
  ].map(ColorValue.parse),
);
final initialPalette = Palette({
  for (final entry in <ColorRole, String>{
    ColorRole.canvas: '#F6F5EF',
    ColorRole.surface: '#FFFFFF',
    ColorRole.ink: '#172A28',
    ColorRole.muted: '#56635E',
    ColorRole.accent: '#166B5C',
    ColorRole.onAccent: '#FFFFFF',
  }.entries)
    entry.key: ColorValue.parse(entry.value),
});
