import 'package:flutter/material.dart';
import '../../../core/design.dart';
import '../application/studio_controller.dart';
import '../domain/palette.dart';
import 'palette_preview.dart';
import 'review_panel.dart';

class StudioScreen extends StatelessWidget {
  const StudioScreen({
    required this.controller,
    required this.state,
    required this.brief,
    required this.note,
    required this.useModel,
    required this.onModelChanged,
    super.key,
  });
  final StudioController controller;
  final StudioState state;
  final TextEditingController brief, note;
  final bool useModel;
  final ValueChanged<bool> onModelChanged;
  Future<void> pick(BuildContext context, ColorRole role) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose ${role.label.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final color in sampleCatalog.colors)
                      Semantics(
                        label: 'Assign ${color.hex} to ${role.label}',
                        button: true,
                        child: InkWell(
                          key: ValueKey('swatch-${color.hex}'),
                          onTap: () {
                            controller.assign(role, color);
                            Navigator.pop(sheet);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 94,
                            child: Column(
                              children: [
                                Container(
                                  height: 62,
                                  decoration: BoxDecoration(
                                    color: paintColor(color),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFD8DED7),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  color.hex,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageTitle(
        'Your next visual language',
        'Good color.\nClear decisions.',
        'Explore a direction. Measure the contrast. Keep the final say.',
      ),
      ColorRibbon(state.palette, height: 92),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StudioBadge(
            '${requiredPairs.where((r) => r.passes(state.palette)).length} / 7 PAIRS PASS',
            good: exportable(state.palette),
          ),
          Text(
            state.dirty ? 'UNSAVED DRAFT' : 'REVISION ${state.revision}',
            style: const TextStyle(
              fontSize: 10,
              color: muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      PalettePreview(state.palette),
      const SizedBox(height: 24),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Design direction'),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('design-brief'),
              controller: brief,
              maxLength: 400,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Describe the mood'),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'On-device AI',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                state.modelAvailable
                    ? 'Ranks validated directions. No network key.'
                    : 'Unavailable here. Rules remain available.',
                style: const TextStyle(fontSize: 12),
              ),
              value: useModel && state.modelAvailable,
              onChanged: state.modelAvailable && !state.busy
                  ? onModelChanged
                  : null,
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('propose'),
                onPressed: state.busy
                    ? null
                    : () => controller.propose(
                        brief.text,
                        useModel: useModel && state.modelAvailable,
                      ),
                child: Text(
                  state.busy
                      ? 'Preparing direction…'
                      : useModel && state.modelAvailable
                      ? 'Suggest a direction'
                      : 'Suggest with rules',
                ),
              ),
            ),
          ],
        ),
      ),
      if (state.proposal != null)
        ReviewPanel(state: state, apply: controller.applyProposal),
      const Eyebrow('Six roles / eight source colors'),
      const SizedBox(height: 14),
      for (final role in ColorRole.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: ListTile(
              key: ValueKey('role-${role.name}'),
              enabled: !state.locks.contains(role) && !state.busy,
              onTap: () => pick(context, role),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: paintColor(state.palette[role]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8DED7)),
                ),
              ),
              title: Text(
                role.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                state.palette[role].hex,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: IconButton(
                key: ValueKey('lock-${role.name}'),
                tooltip: state.locks.contains(role)
                    ? 'Unlock ${role.label}'
                    : 'Lock ${role.label}',
                onPressed: state.busy
                    ? null
                    : () => controller.toggleLock(role),
                icon: Icon(
                  state.locks.contains(role)
                      ? Icons.lock_outline
                      : Icons.lock_open_rounded,
                  color: state.locks.contains(role) ? teal : muted,
                ),
              ),
            ),
          ),
        ),
      const SizedBox(height: 12),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Keep a trace'),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('revision-note'),
              controller: note,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Revision note'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('save-revision'),
                onPressed: state.dirty && !state.busy
                    ? () => controller.save(note.text)
                    : null,
                child: const Text('Save revision'),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Saved on this device. Previous revisions stay intact.',
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ],
        ),
      ),
    ],
  );
}
