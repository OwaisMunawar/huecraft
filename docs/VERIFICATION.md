# Verification record

Local verification date: 2026-11-08. All palettes and briefs are synthetic.

## Automated checks

- 33 non-golden tests passed: pure math/solver/export rules, controller transitions, real SQLite storage, channel validation/failure paths and four screen interactions.
- Domain/application coverage: 279/279 executable lines (100%). Each selected file and their total must remain at least 90%. UI, composition and data adapters are outside this denominator; they have separate interaction, real SQLite and channel tests.
- Reference vectors include black/white 21:1 and identical-color 1:1. `#777777` against white is below 4.5 despite common rounded presentation. Five hundred deterministic random pairs check symmetry and bounds.
- The solver matches a complete two-color oracle for 64 starting assignments. Forty-eight one-role edits of the sample catalog check validity, lock preservation and minimal changes.
- SQLite tests cover close/reopen persistence, two simultaneous stale saves, transaction rollback when updating the head fails, update/delete triggers, malformed snapshots and typed closed-storage failures.
- A regression failed before the reload fix and passes afterward: malformed saved JSON leaves the unsaved palette intact and exposes a typed message.
- Three macOS golden layouts passed with a 0.5% pixel-difference tolerance. A separate test verifies actual platform text scaling at 2× and 375 logical pixels.
- Strict Dart analysis, formatting, import boundaries, actionlint and SwiftLint 0.65.1 passed locally. Swift compilation uses version 6, complete concurrency checking and Swift warnings as errors.

- Official Pub advisory feeds for all 49 locked hosted packages returned zero advisory records on the verification date.

## Actual native execution

Xcode 26.6, dedicated iPhone 17 Pro simulator, iOS 26.5. The unsigned debug app compiled and the final `integration_test/studio_test.dart` workflow passed with the real Foundation Models bridge available.

1. Open the starter palette and its live preview.
2. Enter a synthetic brief requesting a cobalt accent. Foundation Models selects an existing valid direction; the UI labels it On-device AI. The reviewed result changes Accent from `#166B5C` to `#375CDA` without inventing a color or ratio.
3. Apply the proposal, save revision 2, close the controller/database and reopen the same database. Assert the revision and all six colors survived.
4. Change Accent to `#D4ED7B`, lock the other five roles and open Audit. Three required pairs fail.
5. Request a deterministic repair, inspect it, assert every locked role is preserved, then apply. The final repair uses `#56635E` for Accent, choosing the nearest valid RGB tie breaker within the one-change objective.
6. Save revision 3, open Library and preview JSON. Assert the report's schema and saved revision.

The app runs native inference; this is not a mocked channel result. Unit channel tests intentionally use synthetic replies and are separate. The native workflow checks JSON preview, not clipboard completion. It does not establish ranking quality across many design briefs.

## Screenshot provenance

All six PNGs were captured directly with `xcrun simctl io <dedicated-simulator> screenshot`. The app writes an integration-test checkpoint and waits for a host acknowledgement after capture; this prevents the test from advancing into the next transition before the screenshot is written. Captures are unedited. Each final image was opened and checked.

| File | Visible evidence |
| --- | --- |
| `palette-studio.png` | Initial six-role palette, passing count and live UI preview |
| `on-device-direction-review.png` | Actual native ranking, cobalt change and review button |
| `failed-contrast-audit.png` | Deliberately broken accent and three failing pairs |
| `minimum-change-repair-review.png` | Labelled no-model repair, unchanged locked roles and accent replacement |
| `saved-revision-library.png` | Three saved revisions and enabled export previews |
| `verified-token-export.png` | Revision 3, six tokens and exact computed ratios |

## Reproduce

Run the commands in [CONTRIBUTING.md](../CONTRIBUTING.md). Use a new dedicated simulator and invoke `python3 tool/capture_simulator.py <simulator-id>`. The test uses its own `huecraft-verification.db`, recreates only that app-local test database and deletes it afterward. It fails rather than substitutes rules when actual model availability is missing. No physical-device IDs or signing identities are embedded.

## Not verified

Physical hardware, Android runtime, VoiceOver, subjective ranking quality, clipboard completion and production use. The Maestro flow is supplied but unrun. CI builds Android/iOS and checks goldens; it does not run Foundation Models. Passing the selected contrast pairs is not full WCAG conformance.
