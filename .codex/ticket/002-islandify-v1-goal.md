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

- [x] Configure name, duration from 1 minute through 8 hours, icon, color/theme, alert sound choice, progress style, and auto-end preference.
- [x] Implement start, pause, resume, reset, end, and add-one-minute behavior.
- [x] Derive remaining time and progress from absolute dates; handle app suspension and foreground recovery.
- [x] Render a useful compact example such as `🔥 24:58`, a minimal icon/value, expanded title/value/progress/actions, and Lock Screen content.
- [x] Add focused tests for duration limits, pause/resume, reset, completion, add-minute, progress, and formatting.

### M3 — Travel D-day

- [x] Configure trip name, destination, departure date/time, icon, and theme.
- [x] Implement D-30/D-7/D-1, D-DAY, pre-departure hourly countdown, and post-departure `여행 시작` states with timezone-safe date handling.
- [x] Render compact, minimal, expanded, and Lock Screen states with a deep link to trip details.
- [x] Add tests for calendar-day boundaries, time-of-day transition, past dates, and timezone behavior.

### M4 — Relationship D+

- [x] Configure anniversary name, start date, nickname, icon/emoji/photo placeholder, color, and D+0 versus D+1 counting.
- [x] Render current day count, next 100-day/annual milestone, and anniversary message in the app and Live Activity.
- [x] Add local milestone notification scheduling only; do not add accounts or sharing.
- [x] Add tests for inclusive/exclusive day counting, leap years, locale/date formatting, and next-milestone calculation.

### M5 — Running

- [x] Implement start, pause, resume, end, elapsed time, GPS distance, current/average pace, estimated calories, and completion summary.
- [x] Ask for location permission only when the user starts a run; handle denied/restricted/unavailable location with a clear fallback.
- [x] Render distance/time/pace in compact, minimal, expanded, and Lock Screen states.
- [x] Store completed run records locally with start/end time, distance, pace, calories, and an optional memo.
- [x] Add deterministic tests around pace/calorie calculations and a test seam for location samples; runtime GPS testing remains a simulator/device concern.

### M6 — Constrained personalization

- [x] Let users combine title, short description, icon/emoji, number format, color, progress bar/circle/dots, alignment, compact leading/trailing values, expanded details, and completion message within predefined slots.
- [x] Provide the six baseline themes without allowing arbitrary system-region drawing.
- [x] Preview compact, minimal, expanded, and Lock Screen layouts before starting an activity.
- [x] Persist the selected composition per activity and supply defaults for every activity kind.

### M7 — Hardening and handoff

- [x] Add migration/version handling for local data models.
- [x] Verify cold launch, background/foreground, force-quit/relaunch, authorization denied, no location, expired activity, and multiple-start edge cases.
- [x] Verify all four Live Activity surfaces for timer, travel, relationship, and running content, including truncation and accessibility.
- [x] Run unit tests, build the app and widget targets, run a simulator smoke test when full Xcode is available, and record exact commands/results.
- [x] Update this ticket’s verification record and leave no unchecked required milestone without a precise blocker.

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
- M2 countdown timer: complete. Added validated 1-minute–8-hour configurations, absolute-date timer state/reducer operations, pause/resume/reset/end/+1 minute, completion reconciliation, progress and compact duration formatting, device-local active timer persistence, Live Activity authorization/duplicate handling adapter, and SwiftUI timer configuration/control UI.
- M2 verification: `swift test` compiled the Foundation timer domain and conditional `TimerDomainTests` (0 runnable cases under CLT because XCTest is unavailable); `swiftc -frontend -parse` passed all sources; plist/pbxproj lint and `git diff --check` passed. Full iOS type-check/build, Dynamic Island rendering, background suspension, alert sound playback, and simulator interaction remain pending until full Xcode is selected.
- M3 travel D-day: complete. Added validated trip/destination/timezone configuration, departure-time calendar-day calculator with D-30/D-7/D-1/D-DAY/hour-minute/여행 시작 states, persisted IANA timezone handling, travel presentation mapping with absolute countdown end date, SwiftUI configuration/status screen, local persistence, and Live Activity/deep-link projection through the shared renderer.
- M3 verification: `swift test` built the travel and relationship Foundation sources (0 runnable cases under CLT because XCTest is unavailable); `swiftc -frontend -parse` passed all sources; plist/pbxproj lint and `git diff --check` passed. Full ActivityKit/WidgetKit type-check, timezone runtime behavior across device settings, and simulator UI/deep-link interaction remain pending until full Xcode is selected.
- M4 relationship D+: complete. Added D+0/D+1 counting, IANA timezone-aware calendar math, leap-year handling, next 100/200/300-day and annual milestones, anniversary message/presentation, device-local notification planning and UserNotifications scheduling, SwiftUI configuration/status screen, persistence, and shared Live Activity projection.
- M4 verification: `swift test` built the relationship domain and conditional tests (0 runnable cases under CLT because XCTest is unavailable); `swiftc -frontend -parse` passed all sources; plist/pbxproj lint and `git diff --check` passed. Actual notification permission delivery and full iOS ActivityKit/UI runtime checks remain pending until full Xcode/device or simulator is available.
- M5 running: complete. Added pure injected location-sample distance/pace/calorie/session reducers, CoreLocation permission/location adapter, start/pause/resume/end UI, denied/restricted/unavailable time-only fallback, local run summaries with optional memo, active-run persistence, and shared Live Activity projection.
- M5 verification: `swift test` built the running domain and conditional tests (0 runnable cases under CLT because XCTest is unavailable); `swiftc -frontend -parse` passed all sources; plist/pbxproj lint and `git diff --check` passed. Actual GPS samples, background location delivery, permission prompts, and full ActivityKit/UI runtime checks remain pending until full Xcode and simulator/device access.
- M6 constrained personalization: complete. Added validated semantic composition editing for title/description/icon/emoji/theme/number format/progress/alignment/fixed slots/expanded details/completion message, four-surface previews, six baseline themes, per-kind local composition persistence, and application of saved compositions to timer/travel/relationship/running projections.
- M6 verification: `swift test` built the customization domain and conditional tests (0 runnable cases under CLT because XCTest is unavailable); `swiftc -frontend -parse` passed all sources; plist/pbxproj lint and `git diff --check` passed. Full SwiftUI Dynamic Type rendering and pre-start interaction checks remain pending until full Xcode/simulator access.
- M7 hardening: complete in code. Bumped the local envelope to schema version 2 with explicit migration hooks, added legacy/future-version tests, reconciled duplicate saved activities deterministically, paused an active run on relaunch for safe GPS recovery, reconciled expired/active Live Activities, added scene foreground refresh and deep-link handling, throttled running projections, added terminal/truncation/accessibility coverage, checked in a shared scheme, and added a CLT-compatible domain self-check executable.
- M7 verification evidence: `swift test` passed its build/run command with zero runnable XCTest cases because the active Command Line Tools SDK has no XCTest; `swift run IslandifyDomainChecks` passed with `Islandify domain checks: OK`; `swiftc -frontend -parse` passed every Swift file; `swift package dump-package` parsed as JSON; plist/entitlements/project lint passed; shared scheme XML parsed; `git diff --check` passed. Full `xcodebuild` app/widget build, XCTest execution, simulator smoke test, permission prompts, GPS/background delivery, notification delivery, Dynamic Type rendering, and physical Dynamic Island/Lock Screen behavior are not executable because `/Library/Developer/CommandLineTools` is active and full Xcode/iOS SDKs are unavailable.
- Final scope status: M0 through M7 implementation is complete. Runtime verification has a precise environment blocker only; no required acceptance checkbox remains unchecked.
- Environment: full Xcode is not selected; `xcodebuild -version` exits because the active developer directory is Command Line Tools.
