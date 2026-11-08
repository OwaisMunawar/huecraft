import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design.dart';
import '../application/studio_controller.dart';
import '../domain/color_value.dart';
import '../domain/palette.dart';
import 'palette_preview.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    required this.controller,
    required this.state,
    super.key,
  });
  final StudioController controller;
  final StudioState state;
  Future<void> preview(BuildContext context, {bool css = false}) async {
    try {
      final report = controller.export(css: css);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheet) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .75,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    css ? 'CSS variables' : 'JSON tokens',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved revision ${state.revision} · all required pairs pass',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        report,
                        key: const ValueKey('export-content'),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: report));
                        if (sheet.mounted) {
                          ScaffoldMessenger.of(sheet).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Copy to clipboard'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } on StudioFailure catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageTitle(
        'Local history / portable tokens',
        'Keep the good\ndecisions.',
        'Every save adds a revision. Restoring an older one never erases what came after.',
      ),
      Panel(
        color: ink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudioBadge('${state.history.length} SAVED REVISIONS'),
            const SizedBox(height: 18),
            const Text(
              'Ready for the\nnext screen.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Portable JSON tokens and CSS variables. Checked against the palette you actually saved.',
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('export-json'),
                style: FilledButton.styleFrom(
                  backgroundColor: lime,
                  foregroundColor: ink,
                ),
                onPressed: !state.dirty && exportable(state.palette)
                    ? () => preview(context)
                    : null,
                child: const Text('Preview JSON tokens'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const ValueKey('export-css'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                onPressed: !state.dirty && exportable(state.palette)
                    ? () => preview(context, css: true)
                    : null,
                child: const Text('Preview CSS variables'),
              ),
            ),
            if (state.dirty || !exportable(state.palette))
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Save a passing palette to enable export.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      for (final revision in state.history)
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Revision ${revision.revision}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (revision.revision == state.revision)
                    const StudioBadge('CURRENT'),
                ],
              ),
              const SizedBox(height: 12),
              Text(revision.note, style: const TextStyle(color: muted)),
              const SizedBox(height: 16),
              ColorRibbon(revision.palette, height: 45),
              const SizedBox(height: 14),
              TextButton(
                key: ValueKey('restore-${revision.revision}'),
                onPressed: state.busy
                    ? null
                    : () => controller.restore(revision),
                child: const Text('Load as a new draft'),
              ),
            ],
          ),
        ),
      TextButton(
        key: const ValueKey('reload'),
        onPressed: state.busy ? null : controller.reload,
        child: const Text('Discard draft and reload saved palette'),
      ),
    ],
  );
}
