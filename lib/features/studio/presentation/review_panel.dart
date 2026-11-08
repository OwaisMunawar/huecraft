import 'package:flutter/material.dart';
import '../../../core/design.dart';
import '../application/studio_controller.dart';
import '../domain/palette.dart';
import 'palette_preview.dart';

class ReviewPanel extends StatelessWidget {
  const ReviewPanel({required this.state, required this.apply, super.key});
  final StudioState state;
  final VoidCallback apply;
  @override
  Widget build(BuildContext context) {
    final proposal = state.proposal!;
    return Panel(
      key: const ValueKey('proposal-review'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudioBadge(proposal.origin),
          const SizedBox(height: 14),
          const Text(
            'A direction, not a decision.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'All seven required pairs pass. Locked roles are preserved. Review every change before applying.',
          ),
          const SizedBox(height: 18),
          ColorRibbon(proposal.palette),
          const SizedBox(height: 16),
          for (final role in ColorRole.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      role.label,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                  Text(
                    '${state.palette[role].hex} → ${proposal.palette[role].hex}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('apply-proposal'),
              onPressed: state.busy ? null : apply,
              child: const Text('Apply to draft'),
            ),
          ),
        ],
      ),
    );
  }
}
