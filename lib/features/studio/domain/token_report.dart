import 'dart:convert';
import 'color_value.dart';
import 'palette.dart';

String tokenReport(Palette palette, int revision) {
  if (!exportable(palette)) {
    throw const StudioFailure(
      FailureCode.invalidInput,
      'Resolve all required contrast pairs before exporting.',
    );
  }
  if (revision < 1) {
    throw const StudioFailure(
      FailureCode.invalidInput,
      'Save this palette before exporting.',
    );
  }
  return const JsonEncoder.withIndent('  ').convert({
    'schema': 'huecraft.tokens.v1',
    'revision': revision,
    'colorSpace': 'srgb',
    'tokens': palette.toJson(),
    'checks': [
      for (final rule in requiredPairs)
        {
          'foreground': rule.foreground.name,
          'background': rule.background.name,
          'ratio': rule.ratio(palette),
          'minimum': rule.minimum,
          'passed': rule.passes(palette),
        },
    ],
    'scope': 'Opaque sRGB pairs only. Not a WCAG conformance certificate.',
  });
}

String cssReport(Palette palette, int revision) {
  tokenReport(palette, revision);
  return ':root {\n${palette.toJson().entries.map((entry) => '  --${entry.key.replaceAllMapped(RegExp(r'[A-Z]'), (match) => '-${match[0]!.toLowerCase()}')}: ${entry.value};').join('\n')}\n}';
}
