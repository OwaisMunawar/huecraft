import 'package:flutter/material.dart';
import '../../../core/design.dart';
import '../domain/palette.dart';

class ColorRibbon extends StatelessWidget {
  const ColorRibbon(this.palette, {super.key, this.height = 72});
  final Palette palette;
  final double height;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Six palette roles, from canvas to on accent',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (final role in ColorRole.values)
              Expanded(
                child: ColoredBox(
                  color: paintColor(palette[role]),
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class PalettePreview extends StatelessWidget {
  const PalettePreview(this.palette, {super.key});
  final Palette palette;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: paintColor(palette[ColorRole.canvas]),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFD8DED7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.blur_on_rounded,
              color: paintColor(palette[ColorRole.accent]),
            ),
            const SizedBox(width: 8),
            Text(
              'NORTH / STUDIO',
              style: TextStyle(
                color: paintColor(palette[ColorRole.ink]),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const Spacer(),
            Icon(Icons.more_horiz, color: paintColor(palette[ColorRole.muted])),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'A little more\nroom to focus.',
          style: TextStyle(
            color: paintColor(palette[ColorRole.ink]),
            fontSize: 30,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'A working preview of your roles.\nNo hidden contrast adjustments.',
          style: TextStyle(
            color: paintColor(palette[ColorRole.muted]),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
              decoration: BoxDecoration(
                color: paintColor(palette[ColorRole.accent]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Start something',
                style: TextStyle(
                  color: paintColor(palette[ColorRole.onAccent]),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: paintColor(palette[ColorRole.surface]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '01 / DRAFT',
                  style: TextStyle(
                    color: paintColor(palette[ColorRole.ink]),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
