# WristCoach Design System

Created by /plan-design-review on 2026-04-30.

This is the source of truth for implementation styling. `mocks-v5.html` is the visual baseline for color, density, and component feel, except emoji celebration badges are superseded by this document.

## Design Principles

1. The watch is a tool during a lift. Every screen must be glanceable in less than one second.
2. The app should feel like a serious training partner: direct, calm, high contrast, and encouraging without visual noise.
3. Foundation states must use the same visual language as the final product. Degraded mode is not a debug UI.
4. Color is a cue, not the only cue. Use text, shape, ring state, and haptics for important state changes.

## Color Tokens

| Token | Value | Use |
|-------|-------|-----|
| `background` | `#000000` | Watch app canvas |
| `backgroundOuter` | `#111111` | Preview shell only |
| `surface` | `#111111` | Rows, panels, quiet controls |
| `surfaceRaised` | `#1c1c1c` | Selected rows, cards, active chips |
| `stroke` | `#333333` | Dividers, inactive borders |
| `textPrimary` | `#ffffff` | Primary numbers and labels |
| `textSecondary` | `#aaaaaa` | Secondary labels |
| `textTertiary` | `#888888` | Metadata |
| `textMuted` | `#666666` | Disabled/supporting text |
| `actionGreen` | `#30d158` | GO, ready, selected, positive progress |
| `actionBlue` | `#0a84ff` | Active set progress ring |
| `alertPink` | `#ff375f` | STOP, HR, denied/failed state |
| `calibrationOrange` | `#ff9f0a` | Calibration and needs-attention state |
| `achievementGold` | `#ffd60a` | PR-level celebration only |

## Typography

Use watchOS native system typography in SwiftUI (`.system`). Do not use a custom web font in the watch app.

| Role | Size | Weight | Notes |
|------|------|--------|-------|
| Hero number | 42-56pt | Bold | Rep count, elapsed hold, HR, volume |
| Primary label | 14-18pt | Semibold/Bold | Exercise name, CTA text |
| Row label | 12-14pt | Semibold | Queue and picker rows |
| Caption | 9-11pt | Semibold | Uppercase metadata, badges |
| Microcopy | 9-10pt | Regular/Semibold | Status and readiness detail |

Line height must be compact but never clipped. No viewport-based font scaling.

## Spacing And Shape

- Base spacing unit: 4pt.
- Screen horizontal padding: 12-16pt depending on watch size.
- Row gap: 5-8pt.
- Row radius: 10-12pt in watch UI, matching `mocks-v5.html`.
- Progress rings stay visually circular and centered around the hero value.
- Tappable controls must expose at least a 44pt hit target, even when the visible control is smaller.

## Core Components

| Component | Design rule |
|-----------|-------------|
| Primary CTA | Green, high contrast, bottom anchored when possible, 44pt minimum hit target |
| STOP control | Pink/red, always visible during active set, clear text label |
| Queue row | Dark surface, current item has green left accent or border |
| Calibration control | Orange accent, explicit buttons visible alongside Digital Crown support |
| Rep ring | Blue for normal progress, gold only for PR-level success |
| Readiness gate | Compact checklist with 2-3 checks visible before entering active set |
| Degraded banner | Orange or pink status plus plain text reason and next action |
| Summary row | Dense, scan-friendly, no marketing-card treatment |

## Foundation Readiness Gate

The foundation slice must show a real readiness gate after Begin Workout and before Active Set. It is short-lived when everything passes, but visible enough to build trust.

Paths:

```text
Begin Workout
  -> HealthKit OK + audio OK + motion OK -> Active Set
  -> HealthKit fails -> Continue without HR? -> Active Set degraded
  -> Watch speaker fails -> AirPods required? -> Active Set with audio status
  -> Motion unavailable -> Manual rep mode / stop-only mode
```

Required visual states:

| Capability | Ready | Degraded | Failed |
|------------|-------|----------|--------|
| HealthKit | Green check, "HR ready" | Timer-only rest | Permission action or continue without HR |
| Workout session | "Workout active" | Retry visible | Cannot start set until user chooses exit/retry |
| Audio route | "Audio ready" | AirPods required/status shown | Silent mode label, no hidden failure |
| Motion | "Auto-count ready" | Manual +/- or STOP-only mode | Explicit no-auto-count state |
| Fixture validation | Hidden in user UI | Test-only status | Test failure blocks release, not runtime UI |

## Celebration Rules

No emoji badges in the production UI. Use:

- Gold ring and gold hero value for PR-level moments.
- Text labels such as `PR`, `Best`, or `Exceptional lift`.
- Strong success haptic for PR-level moments.
- Medium success haptic for ordinary set completion.

Gold is reserved for real achievement. Routine success stays green, blue, or white.

## Haptics And Audio

- GO tap: light haptic.
- Set complete: medium success haptic.
- PR-level result: strong success haptic.
- Rest ready: light haptic.
- Audio must be routed through the `SpeechAnnouncer` abstraction and guarded by the on-device audio spike.

## Accessibility Contract

- Every tappable control must have a 44pt hit target.
- VoiceOver labels must name the object and state, not just the visible text.
- VoiceOver values:
  - Active set: exercise, weight, set number, current reps, target reps.
  - Rest: current HR or timer-only mode, readiness state, next exercise.
  - Calibration: exercise, current weight, increment, selected action.
  - Readiness gate: each capability status and available fallback action.
- Dynamic Type may increase row and caption text, but hero values keep fixed bounds and truncate surrounding metadata first.
- Reduced Motion disables decorative transitions, animated rings still update instantly to the new value.
- Always-On dim mode keeps the hero value, STOP, and degraded status legible.
- State cannot rely on color alone. Pair color with text, icons, border/ring style, or haptics.

## Small-Watch Layout Rules

For each screen, these are the top three items that must remain visible or one Crown tick away.

| Screen | Must show | Truncation and scroll |
|--------|-----------|-----------------------|
| Muscle Picker | Title/status, selected groups, Start CTA | Muscle rows scroll; CTA stays reachable |
| Exercise Queue | Current exercise, last weight/status, Begin CTA | Secondary exercise rows can scroll |
| Readiness Gate | Overall status, first 2-3 checks, fallback action | Long explanations truncate to one line |
| Calibration | Exercise, weight/target, Start action | Helper copy truncates before controls |
| Active Set | Hero value, STOP, exercise/weight context | Motivation strip can hide first |
| Rest | HR or timer, Ready action, next exercise | Progress detail can collapse |
| Summary | Total volume, PR/status, Done | Exercise list scrolls |

If a layout cannot fit on the smallest supported watch without hiding the action, reduce secondary content before shrinking hit targets.
