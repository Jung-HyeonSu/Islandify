# Islandify

## Project intent

Islandify is a native iOS app that keeps a small, beautiful view of the user’s current time-based activity in Dynamic Island and on the Lock Screen. The first release is local-first and ships one vertical slice at a time: timer, travel D-day, relationship D+, running, then constrained customization.

## Working agreements

- Treat the product brief in `README.md` as the product source of truth. Keep implementation details in the project files and ticket records rather than expanding the root README with transient notes.
- Preserve existing user changes. Before editing, inspect `git status` and keep unrelated work untouched.
- Prefer SwiftUI for app screens and ActivityKit/WidgetKit for Live Activities. Keep `ActivityAttributes` and shared content-state types in a source location included by both the app and widget extension.
- Target iOS 16.1 or newer for the first Live Activities slice. Use availability checks where a code path can be reached on an older supported OS.
- Keep Live Activity views compact, glanceable, and resilient to system truncation. Do not assume the app controls whether Dynamic Island is visible.
- Store the first-release data on device only. Do not add accounts, networking, telemetry, HealthKit, Watch connectivity, weather, flight status, or exchange-rate integrations without an explicit product decision.
- Build behavior around a single source of truth for elapsed/remaining time. Persist absolute dates or timestamps rather than trusting an in-memory timer across suspension.
- Add or update focused tests when changing pure domain logic. Keep UI and ActivityKit integration thin around testable models and formatters.
- Run `git diff --check` after edits. If full Xcode is available, run the simulator build and tests; if only Command Line Tools are available, report that limitation and use syntax/static checks instead of claiming an Xcode build passed.

## Repository layout

- `Islandify/`: iOS app target and SwiftUI screens.
- `IslandifyWidget/`: WidgetKit extension and Live Activity presentation.
- `Shared/`: source shared by the app and widget extension, especially ActivityKit contracts.
- `IslandifyTests/`: unit tests for pure application/domain logic.
- `.agents/skills/islandify-ios/`: project-specific Codex workflow for SwiftUI, ActivityKit, and WidgetKit work.
- `.codex/ticket/`: implementation plans, decisions, and verification records.

## Goal-run protocol

When a long-running `goal` is started for this repository, use `.codex/ticket/002-islandify-v1-goal.md` as the acceptance contract. Work through its milestones inside the same goal, keeping the app buildable after each vertical slice and recording verification evidence in the ticket. Do not declare the goal complete because scaffolding exists or because one feature works; all required feature and platform checkboxes must be satisfied, or the remaining blocker must be stated precisely.

At the start of each goal turn:

1. read `README.md`, the active goal ticket, and the current `git status`;
2. inspect the existing implementation before choosing the next milestone;
3. make a small, coherent batch of changes and run the strongest relevant checks;
4. update the ticket’s progress/evidence section before moving on.

Use `ios_architect` for read-only preflight decisions and `live_activity_reviewer` after ActivityKit surfaces exist. Use `ios_implementer` only for a clearly bounded slice with non-overlapping files.

## Validation commands

When Xcode is installed:

```sh
xcodebuild -project Islandify.xcodeproj -scheme Islandify -sdk iphonesimulator -configuration Debug build
xcodebuild test -project Islandify.xcodeproj -scheme Islandify -destination 'platform=iOS Simulator,name=iPhone 15'
```

Always-safe repository checks:

```sh
git diff --check
```

Goal handoff check:

```sh
sh .codex/hooks/verify_goal.sh --complete
```

If the active developer directory is Command Line Tools rather than full Xcode, use `swiftc -frontend -parse` for Swift syntax checks and validate plist/JSON/TOML structure separately. Do not describe that as a successful iOS build.

## Delegation

Use the project agents for narrow independent work only. `ios_architect` and `live_activity_reviewer` are read-only; they return evidence and recommendations without editing application files. `ios_implementer` edits only an explicitly assigned slice and must return validation evidence.
