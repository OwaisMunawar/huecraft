import 'package:flutter/material.dart';
import '../features/studio/domain/color_value.dart';

const paper = Color(0xFFF6F5EF);
const ink = Color(0xFF172A28);
const muted = Color(0xFF56635E);
const teal = Color(0xFF166B5C);
const lime = Color(0xFFD4ED7B);
Color paintColor(ColorValue color) => Color(0xFF000000 | color.rgb);
ThemeData studioTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: paper,
  colorScheme: ColorScheme.fromSeed(seedColor: teal, surface: paper),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: ink, fontSize: 15, height: 1.45),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: ink,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ink,
      minimumSize: const Size(48, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: paper,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD8DED7)),
    ),
  ),
);

class Panel extends StatelessWidget {
  const Panel({required this.child, super.key, this.color = Colors.white});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 18),
    child: Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE0E4DC)),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    ),
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = muted});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 2,
      color: color,
    ),
  );
}

class StudioBadge extends StatelessWidget {
  const StudioBadge(this.text, {super.key, this.good = true});
  final String text;
  final bool good;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: good ? lime : const Color(0xFFF9D6C7),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: ink,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class PageTitle extends StatelessWidget {
  const PageTitle(this.kicker, this.title, this.description, {super.key});
  final String kicker, title, description;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(kicker),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            fontSize: 38,
            height: 1.06,
            letterSpacing: -1.7,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          description,
          style: const TextStyle(fontSize: 15, height: 1.5, color: muted),
        ),
      ],
    ),
  );
}
