# Roadmap: iPhone companion

Status: active
Started: 2026-10-22

## Why an iPhone app

The watch is the right place to execute a set and the wrong place to plan a month of training. Choosing exercises on a 45mm screen works for an ad hoc session. It does not work for building a named program, comparing last month's volume, or adjusting loads across a week.

The iPhone app adds the two surfaces the watch cannot provide well:

- **Planning.** Build a program once, reuse it, reorder it, and send it to the watch.
- **Review.** See volume, personal records, and session history in one place.

The watch keeps the job it does best: count reps, call the set, gate rest on heart rate, and stay out of the way.

This reverses the original "watchOS only" constraint in `design-doc.md`. The constraint existed to keep the core workout flow independent of a phone. That principle is preserved: the watch never needs the phone during a workout.

## Product principles

1. **The watch works alone.** A program is delivered ahead of time. With no program, the existing muscle picker flow still works.
2. **The phone plans, the watch executes.** Planning UI lives on the phone. The active set stays on the watch.
3. **Programs are data, not code.** A program is a Codable value that the watch validates before use.
4. **Local first.** No accounts, no cloud, no server. Sync happens over WatchConnectivity while both devices are nearby.
5. **Every increment is tested.** Each step lands with tests and a short note in this file.

## Feature: Programs

A program is an ordered list of exercises with target sets, reps, weight, and rest.

```text
Push A
  1. Bench Press          4 x 8   135 lb   rest 120s
  2. Incline Press        3 x 10   50 lb   rest 90s
  3. Chest Fly            3 x 12   80 lb   rest 60s
  4. Tricep Pushdown      3 x 12   40 lb   rest 60s
```

Flow:

```text
iPhone: create program -> Send to Watch
Watch: receive -> validate -> show planned queue -> lift -> log set
iPhone: next launch -> session history and volume
```

The first release covers creating, editing, and sending a program, plus executing it on the watch. History sync follows.

## Architecture

```text
iPhone app (SwiftUI, SwiftData)
        |
        | WatchConnectivity (Codable messages)
        v
Watch app (SwiftUI, SwiftData, HealthKit)
        |
        +--> WristCoachKit (shared models, validation, progression, sync envelope)
```

- **WristCoachKit** is a platform-neutral Swift package. It holds program models, validation, progression rules, and the sync message format. It builds and tests on macOS with `swift test`, so work can continue without Xcode.
- **Watch app** keeps the existing state machine and workout flow. It gains a program receiver and a planned queue.
- **iPhone app** is a new SwiftUI target with its own SwiftData store.
- **Sync** uses a versioned message envelope so older watches can reject messages they do not understand.

## Status

| Surface | Status |
|---------|--------|
| Apple Watch app | Working foundation |
| WristCoachKit | In progress |
| iPhone app | Planned, needs Xcode |
| Phone to watch sync | Planned |
| History sync | Planned |

## Phases

Each step is sized for one focused session. Steps marked "needs Xcode" cannot be verified on a machine with only Command Line Tools.

### Phase 0: Foundation

- [x] **0.1** Product brief, architecture, and roadmap (this file)
- [x] **0.2** `WristCoachKit`: `Program` and `ProgramExercise` with validation
- [x] **0.3** Sample programs: Push A, Pull A, Legs
- [x] **0.4** `ProgramStore` protocol and in-memory store
- [x] **0.5** JSON file store with atomic writes
- [x] **0.6** Volume and set totals for a program
- [x] **0.7** Next-load suggestion per program exercise
- [x] **0.8** CI workflow for WristCoachKit tests

### Phase 1: Sync protocol

- [ ] **1.1** `WatchMessage` envelope with version and message kind
- [ ] **1.2** Program payload validation and size guard before send
- [ ] **1.3** Phone-side sync coordinator with a fake transport
- [ ] **1.4** Watch-side receiver with a fake transport

### Phase 2: iPhone app (needs Xcode)

- [ ] **2.1** Add an iOS app target and shared scheme
- [ ] **2.2** Program list with empty state
- [ ] **2.3** Program detail with exercise summary
- [ ] **2.4** Program editor with add, remove, reorder, and edit
- [ ] **2.5** Send to Watch with delivery status
- [ ] **2.6** History list and volume chart
- [ ] **2.7** Accessibility, Dynamic Type, and dark mode pass

### Phase 3: Watch integration (needs Xcode)

- [ ] **3.1** Add WristCoachKit to the watch target
- [ ] **3.2** Receive and persist the active program
- [ ] **3.3** Build the exercise queue from a program
- [ ] **3.4** Execute target sets, reps, and weight
- [ ] **3.5** Send completed records back to the phone
- [ ] **3.6** Keep the muscle picker as the no-program fallback
- [ ] **3.7** Complication or widget showing the next planned session (stretch)

### Phase 4: Quality

- [ ] **4.1** UI tests for create, edit, send, and execute
- [ ] **4.2** Screenshots and documentation update
- [ ] **4.3** Release notes

## Daily workflow

The daily job follows these rules:

1. Read this file and pick the first unchecked step that does not need Xcode.
2. Implement only that step. Write comments that explain why, not what.
3. Add or update tests with the change.
4. Run `./scripts/test.sh`.
5. Check the box, add one line to the progress log, and add a bullet under today's date in the README changelog.
6. Commit and push to `master` with a descriptive message.
7. Never force push, never rewrite history, and never commit an empty change.

If a step needs Xcode and Xcode is not available, skip it, note it under Blocked, and pick the next unblocked step.

## Blocked

Nothing blocked yet.

## Progress log

- 2026-10-22: 0.1 roadmap and architecture
- 2026-10-22: 0.2 program models, validation, and 8 tests
- 2026-10-22: 0.6 program set totals and volume
- 2026-10-22: 0.8 core test CI workflow
- 2026-10-23: 0.3 sample Push, Pull, and Legs programs
- 2026-10-23: maintenance: exercise id validation, volume overflow fix, AGENTS cleanup
- 2026-10-24: 0.4 program store protocol and in-memory store
- 2026-10-25: 0.5 JSON program store with atomic writes
- 2026-10-26: 0.7 next-load suggestions for program exercises
