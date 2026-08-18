# 002 — Islandify v1 implementation goal

## Goal statement

Build the first usable native iOS release of Islandify: a local-first app that lets a user configure one active time-based activity and keep checking it in the app, Dynamic Island, and Lock Screen. Implement the features below in one durable goal, using separate vertical milestones and keeping the project buildable after each milestone.

## Product promise

The product is not an unrestricted Dynamic Island drawing tool. It is a small, attractive, glanceable view of a user’s current time, trip, relationship milestone, or run. The system decides when Live Activities and Dynamic Island surfaces are shown.

## Platform and architecture contract

- Native SwiftUI iOS app with a WidgetKit extension using ActivityKit Live Activities.
- Support compact, minimal, expanded, and Lock Screen presentations for every activity type that exposes a Live Activity.
- iOS 16.1+ minimum for the first release; use availability checks for APIs that require newer OS versions.
- Keep each `ActivityAttributes` and `ContentState` contract in shared source compiled into both the app and widget extension.
- Persist local state using a versionable device-local store. Persist absolute dates/timestamps, not only in-memory timer state.
- Keep calculations and formatting in pure testable types. Keep ActivityKit calls behind small services/managers.
- No accounts, backend, social graph, telemetry, ads, HealthKit, Apple Watch connectivity, voice coaching, weather, flight status, or exchange-rate integrations in v1.
- Do not add external dependencies unless the goal records why a system framework cannot provide the behavior.

## Milestones

### M0 — Clean project foundation

- [x] Create an Xcode project with app, WidgetKit extension, and unit-test targets.
- [x] Set bundle identifiers, deployment target, signing-safe simulator configuration, and Live Activities capability/Info.plist settings.
- [x] Establish app, widget, shared, domain, and test boundaries.
- [x] Add a deterministic local persistence abstraction and a preview/sample data path.
- [x] Add a minimal app shell that launches from a clean checkout.

### M1 — Shared activity and customization primitives

- [x] Define activity kinds, lifecycle phases, theme palette, icon/emoji, progress style, and compact leading/trailing content configuration.
- [x] Define a versioned shared presentation model that can render within Apple’s fixed Live Activity regions.
- [x] Add the six baseline themes: Minimal Black, Pastel Couple, Travel Blue, Neon Timer, Running Green, and Cream Diary.
- [x] Add accessibility labels, contrast-safe colors, Dynamic Type behavior, and sensible truncation fallbacks.

### M2 — Countdown timer

- [ ] Configure name, duration from 1 minute through 8 hours, icon, color/theme, alert sound choice, progress style, and auto-end preference.
- [ ] Implement start, pause, resume, reset, end, and add-one-minute behavior.
- [ ] Derive remaining time and progress from absolute dates; handle app suspension and foreground recovery.
- [ ] Render a useful compact example such as `🔥 24:58`, a minimal icon/value, expanded title/value/progress/actions, and Lock Screen content.
- [ ] Add focused tests for duration limits, pause/resume, reset, completion, add-minute, progress, and formatting.

### M3 — Travel D-day

- [ ] Configure trip name, destination, departure date/time, icon, and theme.
- [ ] Implement D-30/D-7/D-1, D-DAY, pre-departure hourly countdown, and post-departure `여행 시작` states with timezone-safe date handling.
- [ ] Render compact, minimal, expanded, and Lock Screen states with a deep link to trip details.
- [ ] Add tests for calendar-day boundaries, time-of-day transition, past dates, and timezone behavior.

### M4 — Relationship D+

- [ ] Configure anniversary name, start date, nickname, icon/emoji/photo placeholder, color, and D+0 versus D+1 counting.
- [ ] Render current day count, next 100-day/annual milestone, and anniversary message in the app and Live Activity.
- [ ] Add local milestone notification scheduling only; do not add accounts or sharing.
- [ ] Add tests for inclusive/exclusive day counting, leap years, locale/date formatting, and next-milestone calculation.

### M5 — Running

- [ ] Implement start, pause, resume, end, elapsed time, GPS distance, current/average pace, estimated calories, and completion summary.
- [ ] Ask for location permission only when the user starts a run; handle denied/restricted/unavailable location with a clear fallback.
- [ ] Render distance/time/pace in compact, minimal, expanded, and Lock Screen states.
- [ ] Store completed run records locally with start/end time, distance, pace, calories, and an optional memo.
- [ ] Add deterministic tests around pace/calorie calculations and a test seam for location samples; runtime GPS testing remains a simulator/device concern.

### M6 — Constrained personalization

- [ ] Let users combine title, short description, icon/emoji, number format, color, progress bar/circle/dots, alignment, compact leading/trailing values, expanded details, and completion message within predefined slots.
- [ ] Provide the six baseline themes without allowing arbitrary system-region drawing.
- [ ] Preview compact, minimal, expanded, and Lock Screen layouts before starting an activity.
- [ ] Persist the selected composition per activity and supply defaults for every activity kind.

### M7 — Hardening and handoff

- [ ] Add migration/version handling for local data models.
- [ ] Verify cold launch, background/foreground, force-quit/relaunch, authorization denied, no location, expired activity, and multiple-start edge cases.
- [ ] Verify all four Live Activity surfaces for timer, travel, relationship, and running content, including truncation and accessibility.
- [ ] Run unit tests, build the app and widget targets, run a simulator smoke test when full Xcode is available, and record exact commands/results.
- [ ] Update this ticket’s verification record and leave no unchecked required milestone without a precise blocker.

## Definition of done

The goal is complete only when M0–M7 are implemented or an explicitly documented environment blocker prevents the remaining verification. The final handoff must include:

- changed file summary;
- supported OS and framework assumptions;
- build/test/smoke-test commands and results;
- known limitations that are intentionally outside v1;
- confirmation that no user changes were discarded.

## Progress and verification record

- Harness baseline: complete.
- M0 clean project foundation: complete. Added `Islandify.xcodeproj` with app, WidgetKit extension, and unit-test targets, iOS 16.1 build settings, signing-safe simulator settings, Live Activities plist support, shared/domain/test directories, a versioned JSON store, preview data, and a minimal SwiftUI shell.
- M0 verification: `swiftc -frontend -parse` passed for all Swift sources; `swift test` completed with zero runnable cases because the active Command Line Tools SDK does not provide XCTest; all plist files and `Islandify.xcodeproj/project.pbxproj` passed `plutil -lint`; `git diff --check` passed. `xcodebuild` and simulator execution remain pending because the active developer directory is `/Library/Developer/CommandLineTools` rather than full Xcode.
- M1 shared primitives: complete. Added `ActivityKind`, lifecycle phases, icon/theme/progress/slot models, six contrast-safe themes, constrained compact/minimal/expanded/Lock Screen render models, pure date/time helpers, and the shared `IslandifyActivityAttributes.ContentState` contract used by app and Widget target memberships.
- M1 verification: `swift test` built the Foundation domain and conditional Xcode tests (0 runnable cases under CLT because XCTest is unavailable); `swiftc -frontend -parse` passed all Swift sources; `plutil -lint` passed plist, entitlements, and project files; `git diff --check` passed. ActivityKit/WidgetKit type-checking and runtime surface review remain pending until full Xcode is selected.
- App implementation: M0 and M1 complete; M2 and later milestones remain in progress.
- Environment: full Xcode is not selected; `xcodebuild -version` exits because the active developer directory is Command Line Tools.
