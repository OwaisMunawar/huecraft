# Architecture decisions

## ADR 1: colors are opaque values, not UI objects

The domain accepts exactly six sRGB hex digits, stores integer RGB channels and calculates linearized relative luminance. It cannot import Flutter, storage or channel APIs. Alpha and non-sRGB spaces are rejected rather than guessed. A UI `Color` conversion belongs in shared presentation code.

Rejected: parsing arbitrary CSS strings or letting `Color` carry an unexamined alpha/color space through the contrast calculation. The current tool deliberately supports a smaller explicit input domain.

## ADR 2: compare exact ratios against declared usage

The seven pairs name their foreground, background, minimum and intended use. Decisions compare the full floating-point ratio; two-decimal UI text is presentation only. The rules use the normative [WCAG relative-luminance and contrast definitions](https://www.w3.org/TR/WCAG22/#dfn-relative-luminance). The threshold is 4.5 for normal/button text and 3 for the two declared control boundaries. No large-text inference is performed.

Rejected: treating every color pair as meaningful or calling a passing palette an accessible application. Typography, focus, interactions, images and other requirements are outside this measurement.

## ADR 3: bounded, deterministic minimum-change repair

The solver enumerates assignments in role order, tests constraints as soon as both roles are bound and prunes branches whose accumulated cost cannot improve the best result. Locked roles have one candidate. The cost is `changedRoles * 2,000,000 + sum(squaredRgbDistance)`. Six maximum RGB distances total 1,170,450, so the primary objective always dominates the tie breaker.

A completed search returns a globally minimum-cost valid assignment within the supplied catalog and locks. It is not a perceptual optimum. A 150,000-node budget stops work with a typed failure; it never returns a partially searched result as optimal. Pure tests compare the result with exhaustive enumeration on a small catalog and check all 48 single-role edits of the sample palette.

Rejected: unconstrained model-generated colors, silently changing locks, greedy fixes with no global comparison, or unbounded search in an interactive tool. The domain accepts 2–12 unique colors; the current app exposes a fixed eight-color catalog.

## ADR 4: the model ranks valid options

Proposal construction starts with the current accent, then explores chromatic alternatives, repairing each direction while treating its accent and session locks as fixed. Duplicate assignments are removed and at most three options are offered. Guided native generation returns an integer index only. Both sides validate its range. Dart rechecks catalog membership, contrast, locks and the draft epoch before displaying a proposal. Apply validates again.

Rejected: asking a language model to calculate contrast or to persist a result. There are no tools, network-provider credentials or model-issued writes. Briefs are untrusted data, length-bounded and sent to the native on-device model. Rules implement the same engine port and are labelled. Errors never silently masquerade as native success.

## ADR 5: explicit drafts, review and revision commits

Changing a role or lock advances a draft epoch and invalidates a pending proposal. A late model response cannot target the newer draft. Applying a proposal changes only session state. Save uses an expected database revision and writes the snapshot and head pointer in one transaction. Stale saves preserve the draft and show a reload decision. Reload failures keep the current draft.

Historical rows have update/delete triggers. Restoring a revision produces a draft; a new save records the restoration without rewriting intervening history. Unsaved drafts and failed pair checks block export. JSON and CSS derive from the same saved snapshot and never invent a revision number.

Rejected: autosaving model output, mutable history, or optimistic export before persistence. Session drafts and locks are currently not persisted; this limitation is visible in the README.

## ADR 6: injected ports and small state machinery

`StudioController` is pure Dart and receives repository, engines and clock. It emits immutable snapshots over a stream. UI primitives are shared; feature screens depend on the controller and domain, not storage adapters. `bootstrap.dart` alone composes sqflite and channel implementations. The architecture checker rejects platform imports in domain and adapter/screen imports in application.

Rejected: adding a global service locator or a state framework only to move a single workspace's state around. The ports remain usable with another composition or presentation layer.

## Storage and operational limits

SQLite is local and uses one workspace head. Optimistic revision checks handle conflicting saves, not distributed synchronization. History is unbounded and read as a list. There is no auth, backup, encryption layer or network service. Storage errors never reset data automatically. `schema: huecraft.tokens.v1` is an application-specific JSON report, not a claim of Design Tokens Community Group compliance or a backup format.
