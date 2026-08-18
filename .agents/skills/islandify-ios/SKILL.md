---
name: islandify-ios
description: Build and review Islandify’s native iOS SwiftUI, ActivityKit, WidgetKit, and Live Activities features. Use for this repository’s timer, D-day, relationship counter, running, or constrained Dynamic Island customization work; do not use for unrelated generic iOS tasks.
---

# Islandify iOS workflow

## Product boundary

Islandify is a local-first glanceable activity app. The initial implementation should establish a reliable timer vertical slice before adding travel, relationship, running, or visual customization features. Keep the Dynamic Island UI within Apple’s compact, minimal, expanded, and Lock Screen surfaces; it is not an unrestricted canvas.

## Architecture invariants

- Use SwiftUI for the app and WidgetKit’s `ActivityConfiguration` for the Live Activity.
- Keep the ActivityKit contract in `Shared/` so the app and widget extension compile against the same `ActivityAttributes` and `ContentState` definitions.
- Model countdowns with absolute `Date` values and derive remaining time from the current clock. Pause and resume by changing the stored end date/remaining duration, not by relying on a process-local `Timer`.
- Keep ActivityKit start/update/end calls behind a small service or manager so domain logic can be unit tested without a Live Activity process.
- Prefer system-rendered date intervals and text for live countdowns where possible; avoid high-frequency manual updates.
- Keep local persistence explicit and versionable. Never introduce accounts or network-backed state for the first release.

## Live Activity review checklist

For each activity, verify all of these surfaces and states:

1. compact leading/trailing content is readable at a glance;
2. minimal presentation has a meaningful fallback;
3. expanded presentation exposes the primary value and only essential actions;
4. Lock Screen presentation remains useful without Dynamic Island;
5. active, paused, completed, and ended states have deterministic content;
6. accessibility labels and Dynamic Type do not hide the primary value;
7. the activity respects system lifecycle, authorization, and possible truncation.

## Implementation sequence

1. Define pure models and formatting rules.
2. Add the shared ActivityKit contract.
3. Add the app-side activity manager and the smallest usable SwiftUI screen.
4. Add WidgetKit/Live Activity layouts for all required surfaces.
5. Add focused tests for duration, pause/resume, and display formatting.
6. Validate with the strongest available toolchain and record any Xcode/simulator limitation in `.codex/ticket/`.

## Verification discipline

Read the current ticket and `git status` before changing files. Keep changes narrow and cite exact files in handoff notes. If full Xcode is unavailable, run syntax and configuration checks, inspect the generated project structure, and state that simulator/runtime validation remains pending.

## Long-running goal behavior

When this skill is used inside a `goal`, treat `.codex/ticket/002-islandify-v1-goal.md` as the product contract. Complete milestones in order, keep the project in a buildable state, and record the exact checks and any environment limitation in the ticket. Do not silently drop a feature because it is larger than the timer slice; split it into a smaller vertical slice and continue within the same goal. Do not add backend, account, HealthKit, Watch, or external data integrations unless the goal explicitly changes the scope.
