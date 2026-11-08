import 'package:flutter/material.dart';
import 'core/design.dart';
import 'features/studio/application/studio_controller.dart';
import 'features/studio/presentation/audit_screen.dart';
import 'features/studio/presentation/library_screen.dart';
import 'features/studio/presentation/studio_screen.dart';

class HuecraftApp extends StatelessWidget {
  const HuecraftApp({required this.controller, super.key});
  final StudioController controller;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Huecraft',
    debugShowCheckedModeBanner: false,
    theme: studioTheme(),
    home: StudioShell(controller: controller),
  );
}

class StudioShell extends StatefulWidget {
  const StudioShell({required this.controller, super.key});
  final StudioController controller;
  @override
  State<StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<StudioShell> {
  int tab = 0;
  bool useModel = true;
  final brief = TextEditingController(
    text: 'A calm, focused dashboard for an independent creative studio.',
  );
  final note = TextEditingController(text: 'Reviewed palette direction');
  @override
  void dispose() {
    brief.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<StudioState>(
    stream: widget.controller.changes,
    initialData: widget.controller.state,
    builder: (context, snapshot) {
      final state = snapshot.data ?? widget.controller.state;
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 34,
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: teal,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.blur_on_rounded,
                              color: lime,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'huecraft',
                                style: TextStyle(
                                  fontSize: 25,
                                  color: ink,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const StudioBadge('LOCAL STUDIO'),
                  ],
                ),
              ),
              if (state.busy) const LinearProgressIndicator(minHeight: 2),
              if (state.message != null)
                Container(
                  key: const ValueKey('status-message'),
                  width: double.infinity,
                  color: lime,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  child: Text(
                    state.message!,
                    style: const TextStyle(fontSize: 12, color: ink),
                  ),
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: SingleChildScrollView(
                      key: ValueKey('page-$tab'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                      child: switch (tab) {
                        0 => StudioScreen(
                          controller: widget.controller,
                          state: state,
                          brief: brief,
                          note: note,
                          useModel: useModel,
                          onModelChanged: (value) =>
                              setState(() => useModel = value),
                        ),
                        1 => AuditScreen(
                          controller: widget.controller,
                          state: state,
                        ),
                        _ => LibraryScreen(
                          controller: widget.controller,
                          state: state,
                        ),
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) => setState(() => tab = value),
          backgroundColor: Colors.white,
          indicatorColor: lime,
          destinations: const [
            NavigationDestination(
              key: ValueKey('nav-studio'),
              icon: Icon(Icons.palette_outlined),
              selectedIcon: Icon(Icons.palette),
              label: 'Studio',
            ),
            NavigationDestination(
              key: ValueKey('nav-audit'),
              icon: Icon(Icons.rule_outlined),
              label: 'Audit',
            ),
            NavigationDestination(
              key: ValueKey('nav-library'),
              icon: Icon(Icons.layers_outlined),
              label: 'Library',
            ),
          ],
        ),
      );
    },
  );
}
