# Contributing

Use Flutter 3.44.2 / Dart 3.12.2. The verified native toolchain is Xcode 26.6; Foundation Models needs an available iOS 26 environment. Run:

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze --fatal-infos
dart run tool/check_architecture.dart
flutter test --coverage --exclude-tags golden
dart run tool/coverage_gate.dart
flutter test --tags golden
```

Keep business rules in pure Dart domain files. Application orchestration imports ports and domain logic; `bootstrap.dart` composes adapters. UI imports no data implementations. Add a regression check that fails before a behavior fix.

Real SQLite tests exercise persistence. Screen tests inject a memory repository so their fake animation clock does not depend on native database scheduling; they do not replace the persistence tests. Channel tests supply invalid replies and failures; the native integration test uses actual Foundation Models.

Golden tests run on macOS with a 0.5% pixel-difference tolerance. Review visual changes before regenerating them with `flutter test --tags golden --update-goldens`.

## Native workflow

Create your own dedicated simulator from an installed iOS 26 runtime. Do not reuse another project's simulator or use physical hardware. Then:

```sh
flutter build ios --simulator --no-codesign --debug
python3 tool/capture_simulator.py <dedicated-simulator-id>
```

The capture script runs the integration test and writes unedited PNGs at synchronized checkpoints. It requires real native model availability and uses only its own app-local test database. Delete only the simulator and build artifacts you created afterward. The Maestro flow expects `--dart-define=DEMO=true`; it has not been run in the verification environment.

Use synthetic data in tests and captures. Never commit local configuration, databases, signing identifiers or credentials. The token report is an application-specific schema, and new fields need versioning decisions and round-trip validation.
