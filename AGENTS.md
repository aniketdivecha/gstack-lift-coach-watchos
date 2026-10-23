# AGENTS.md

Working notes for this repository.

## What this is

WristCoach is a strength training app for Apple Watch, with an iPhone companion in progress. The watch runs the workout. The phone will plan and review it. Shared program models, validation, and sync types live in `WristCoachKit`.

The watch must stay usable without a phone during a workout. If a change breaks that, it is the wrong change.

## Commands

| Task | Command |
|------|---------|
| Core tests | `./scripts/test.sh` |
| Watch tests | Open `WristCoach.xcodeproj`, select the `WristCoach` scheme, press Cmd+U |
| App build | Needs Xcode 26 or later and the watchOS 26 SDK |

`WristCoachKit` tests run on macOS with Command Line Tools. The app targets need full Xcode.

## Layout

- `WristCoach/`: watch app. SwiftUI, SwiftData, HealthKit, CoreMotion.
- `WristCoachKit/`: platform-neutral package for programs, validation, and sync messages.
- `Tests/`: watch app tests and the bench press motion fixture.
- `docs/ROADMAP.md`: phases, status, and the daily progress log.
- `scripts/test.sh`: one command for the core tests.

## Conventions

- Swift 6, SwiftUI, SwiftData, Swift Testing.
- No accounts, no cloud, no server. WatchConnectivity is the only bridge between devices.
- Programs are data. Validate them before the watch sees them.
- One idea per commit. Prefix with `feat:`, `fix:`, `docs:`, `test:`, `ci:`, or `chore:`.
- Update the README or roadmap when behavior changes.
- Comments explain why. If a comment only explains what the code does, rename the code instead.
- New core files need tests. New tests need a reason to exist.

## Guardrails

- Never commit `build/`, `.gstack-screenshots/`, or local credentials.
- Never force push or rewrite history.
- Do not change the deployment target without testing on a real watch.
- The gstack skill pack in `.agents/skills` is local tooling and is ignored by git. Reinstall it with `npx gstack-codex init --project` if needed.

## Tone

Dry, short, and rare. A joke in a comment should survive being read twice.
