import 'package:flutter/material.dart';
import '../../../core/design.dart';
import '../application/studio_controller.dart';
import '../domain/palette.dart';
import 'review_panel.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen({required this.controller, required this.state, super.key});
  final StudioController controller;
  final StudioState state;
  @override
  Widget build(BuildContext context) {
    final failures = requiredPairs
        .where((rule) => !rule.passes(state.palette))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle(
          'Deterministic / opaque sRGB',
          'Measure it.\nThen trust it.',
          'Exact WCAG contrast math for seven declared text and control pairs.',
        ),
        Panel(
          color: ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudioBadge(
                failures == 0
                    ? 'ALL REQUIRED PAIRS PASS'
                    : '$failures PAIRS NEED ATTENTION',
                good: failures == 0,
              ),
              const SizedBox(height: 18),
              Text(
                '$failures',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 68,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Failing pairs. Export requires all seven to pass.',
                style: TextStyle(color: Colors.white, height: 1.5),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('repair'),
                  style: FilledButton.styleFrom(
                    backgroundColor: lime,
                    foregroundColor: ink,
                  ),
                  onPressed: state.busy ? null : controller.repair,
                  child: const Text('Review minimum-change repair'),
                ),
              ),
            ],
          ),
        ),
        if (state.proposal != null)
          ReviewPanel(state: state, apply: controller.applyProposal),
        for (final rule in requiredPairs)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rule.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    StudioBadge(
                      rule.passes(state.palette) ? 'PASS' : 'FAIL',
                      good: rule.passes(state.palette),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: paintColor(state.palette[rule.background]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8DED7)),
                  ),
                  child: Text(
                    'Readable by design.',
                    style: TextStyle(
                      color: paintColor(state.palette[rule.foreground]),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${rule.ratio(state.palette).toStringAsFixed(2)}:1',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      '${rule.usage}\nRequires ${rule.minimum}:1',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Semantics(
                  label:
                      '${rule.label}: exact ratio ${rule.ratio(state.palette)}, required ${rule.minimum}',
                  child: LinearProgressIndicator(
                    value: rule.ratio(state.palette) / 21,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(5),
                    color: rule.passes(state.palette)
                        ? teal
                        : const Color(0xFF9A3D20),
                    backgroundColor: paper,
                  ),
                ),
              ],
            ),
          ),
        const Text(
          'Decisions use unrounded ratios. Opaque solid sRGB only: no gradients, translucency, images, typography assessment or full WCAG conformance claim.',
          style: TextStyle(color: muted, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }
}
