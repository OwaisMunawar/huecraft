import 'package:flutter/material.dart';
import 'app.dart';
import 'bootstrap.dart';
import 'core/design.dart';
import 'features/studio/application/studio_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudioBootstrap());
}

class StudioBootstrap extends StatefulWidget {
  const StudioBootstrap({super.key});
  @override
  State<StudioBootstrap> createState() => _StudioBootstrapState();
}

class _StudioBootstrapState extends State<StudioBootstrap> {
  late Future<StudioController> opening = openStudio();
  @override
  Widget build(BuildContext context) => FutureBuilder<StudioController>(
    future: opening,
    builder: (context, snapshot) {
      if (snapshot.hasData) return HuecraftApp(controller: snapshot.data!);
      return MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: snapshot.hasError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Your saved studio could not be opened. No data was reset.',
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () =>
                                setState(() => opening = openStudio()),
                            child: const Text('Try again'),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );
    },
  );
}
