# 001 — Harness baseline

## Goal

Create the repository-level Codex harness that can drive the full Islandify v1 implementation as one durable goal. The timer is the first implementation milestone described by the v1 goal ticket; this baseline ticket does not claim that application code has been implemented.

## Product decisions

- Native SwiftUI app with a WidgetKit extension.
- iOS 16.1+ deployment target for Live Activities.
- Device-local state only for the first release.
- Timer is the first feature; travel D-day, relationship D+, running, and customization follow as separate slices.
- Use absolute timestamps for countdown correctness through app suspension.

## Harness acceptance

- `AGENTS.md` describes product boundaries, layout, validation, and delegation.
- `.agents/skills/islandify-ios/SKILL.md` is discoverable and scoped to this repository.
- `.codex/config.toml`, `.codex/hooks.json`, `.codex/hooks/`, `.codex/agents/`, and `.codex/rules/` contain valid project-scoped configuration.
- The stop hook validates required harness files without modifying the repository.

## Verification record

Initial environment inspection: the repository has no existing Xcode project, and the active developer directory is Command Line Tools rather than full Xcode. The v1 goal must include static/syntax validation and leave simulator/runtime verification explicitly pending until full Xcode is selected.
