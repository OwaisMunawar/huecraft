# Security and data scope

Report a suspected issue privately to the repository owner through the contact link on the GitHub profile. Do not post personal design briefs, local databases or credentials in an issue.

## Data boundary

Huecraft has no account, server or API-provider integration. Briefs and candidate palettes are passed to Apple's native on-device model through a bounded channel. The model returns a candidate index, not an action. Dart checks the index, catalog, current draft epoch, role locks and measured contrast; a person must apply and save.

Untrusted briefs are length-bounded, with a native payload bound as well. Guided output and prompting are not treated as security guarantees. Candidate membership and deterministic validation are the actual boundaries. A 45-second Dart timeout bounds UI waiting but does not cancel the OS task.

## Local persistence

Snapshots and head updates are atomic. Expected-revision checks reject stale saves. History triggers reject normal update/delete operations but cannot protect against external database editing. There is no extra database encryption, biometric gate, backup, retention or cloud synchronization. Saved palettes persist; unsaved drafts and session locks do not.

Copying an export places it on the system clipboard. Other clipboard-capable software may read it. JSON tokens are a portable report, not a signed document or backup format.

## Contrast scope

Only the seven declared opaque solid-sRGB pairs are evaluated. No whole-application accessibility or regulatory compliance claim follows from a passing report. Typography, focus, gradients, translucency, images and other interaction requirements need separate checks.

## Dependencies

Flutter and native toolchains are pinned for reproducibility; weekly compatible dependency updates run through CI and major upgrades require review. Official Pub advisory feeds for all 49 locked hosted packages were checked on 2026-11-08 and returned zero advisory records. This is a point-in-time check, not a guarantee against unknown vulnerabilities.
