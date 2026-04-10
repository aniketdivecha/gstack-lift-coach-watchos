# TODOS

Deferred items from /plan-eng-review 2026-04-10. Each item has context for future-you.

## v2 — Algorithm & Data

### Fatigue fingerprint (per-user HR recovery curves)
- **What:** Learn personal HR drop curve per exercise over 4-6 weeks of real data.
- **Why:** Upgrade from fixed 115 BPM recovery target to personalized "your HR usually drops to X by second Y after this exercise." Better rest timing → better training density.
- **Pros:** Natural differentiator. Data model already captures `startHR`, `endHR`, `restDuration`, `userOverrode` per `RestRecord`.
- **Cons:** Needs weeks of data to be meaningful. Can't ship on day 1 even if built.
- **Context:** Flagged in design-doc.md "Cross-Model Perspective" section. Flow: aggregate `RestRecord` by `exerciseId`, fit decay curve, use for future rest targets.
- **Depends on:** v1 shipped and used regularly enough to accumulate 4+ weeks of rest data per exercise.

### Per-set SwiftData auto-save (crash recovery)
- **What:** Save `ExerciseRecord` to SwiftData immediately after each set, not batched at session end.
- **Why:** Mid-workout crash currently loses the entire session. `HKWorkoutSession` ends automatically on crash/wrist-removal (design-doc.md:389).
- **Pros:** Durability. Low complexity (SwiftData handles the persistence).
- **Cons:** Slightly more write I/O. Battery impact minimal.
- **Context:** v1 explicitly accepts the loss. Upgrade when you've had one crash at the gym.
- **Depends on:** v1 SwiftData model already in place.

### Adaptive per-user HR target
- **What:** Replace fixed 115 BPM rest target with a computed value from the user's own history.
- **Why:** v1 logs `restDuration`, `endHR`, `startHR`, `userOverrode` per rest period specifically to enable this.
- **Pros:** More accurate rest gating. Less user override.
- **Cons:** Needs data from 10+ workouts to stabilize.
- **Context:** Prior step toward fatigue fingerprint. Simple heuristic: 10th-percentile of `endHR` where `userOverrode == false`.
- **Depends on:** v1 shipped, RestRecord log accumulated.

### Physical velocity (m/s) from raw acceleration
- **What:** Compute true bar velocity from `userAcceleration`, not just cadence intervals.
- **Why:** Enables velocity-based autoregulation ("stop the set when bar velocity drops below 0.3 m/s"). The gold standard for strength training autoregulation.
- **Pros:** Upgrade path from cadence-based fatigue. Field name `peakVelocities` already picked for this.
- **Cons:** Requires integrating acceleration → velocity with drift correction. Non-trivial signal processing.
- **Context:** Deliberately future-proofed in the design doc naming. `ExerciseRecord.repIntervals` stores cadence for v1, `peakVelocities` reserved for physical velocity in v2.
- **Depends on:** Reliable rep detection in v1, CMDeviceMotion wiring in v1.

## v2+ — Distribution & Tooling

### iPhone companion app + TestFlight distribution
- **What:** iPhone-side app for history/charts. TestFlight build for install-without-Xcode.
- **Why:** v1 is Xcode-direct-to-device, personal use. If you want to share with friends or install without re-building, you need the distribution path.
- **Pros:** Unlocks sharing. Enables richer history views on the bigger iPhone screen.
- **Cons:** Apple Developer account ($99/yr), App Store review (~1 week), companion architecture adds complexity.
- **Context:** v1 is deliberately watch-only. Do not start this until v1 is used in real workouts for 4+ weeks.
- **Depends on:** v1 shipped and personally validated.

### XCUITest E2E UI tests
- **What:** UI automation tests that drive the watch UI in simulator.
- **Why:** Belt-and-suspenders coverage on top of the state machine tests.
- **Pros:** Catches UI regressions invisible to unit tests.
- **Cons:** XCUITest on watchOS is slow and flaky. The protocol-fronted state machine decision in /plan-eng-review means most flows are already testable without UI.
- **Context:** Consider ONLY if state machine + view unit tests prove insufficient. Do not add preemptively.
- **Depends on:** v1 test suite (Swift Testing + state machine tests) showing gaps that UI tests would fill.

### Crash reporting / analytics
- **What:** Sentry / Crashlytics / os.log pipeline for production crash visibility.
- **Why:** v1 is personal use — Console.app is fine. If you ever distribute, you need visibility.
- **Pros:** Debug distant users without reproducing.
- **Cons:** Complexity, privacy consideration, third-party dependency.
- **Context:** Only needed once distribution is real. Do not add for personal use.
- **Depends on:** Distribution decision (TestFlight / App Store).
