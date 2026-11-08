import 'dart:math' as math;

enum FailureCode {
  invalidInput,
  impossible,
  budget,
  stale,
  unavailable,
  model,
  storage,
}

final class StudioFailure implements Exception {
  const StudioFailure(this.code, this.message);
  final FailureCode code;
  final String message;
  @override
  String toString() => message;
}

final class ColorValue {
  const ColorValue._(this.rgb);
  factory ColorValue.parse(String source) {
    final value = source.trim();
    if (!RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(value)) {
      throw const StudioFailure(
        FailureCode.invalidInput,
        'Use exactly six opaque sRGB hex digits.',
      );
    }
    return ColorValue._(int.parse(value.replaceFirst('#', ''), radix: 16));
  }
  final int rgb;
  String get hex => '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  int get red => (rgb >> 16) & 255;
  int get green => (rgb >> 8) & 255;
  int get blue => rgb & 255;
  double get luminance {
    double linear(int byte) {
      final c = byte / 255;
      return c <= 0.04045
          ? c / 12.92
          : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    return .2126 * linear(red) + .7152 * linear(green) + .0722 * linear(blue);
  }

  double contrast(ColorValue other) {
    final a = luminance;
    final b = other.luminance;
    return (math.max(a, b) + .05) / (math.min(a, b) + .05);
  }

  int distance(ColorValue other) =>
      (red - other.red) * (red - other.red) +
      (green - other.green) * (green - other.green) +
      (blue - other.blue) * (blue - other.blue);
  @override
  bool operator ==(Object other) => other is ColorValue && rgb == other.rgb;
  @override
  int get hashCode => rgb.hashCode;
}
