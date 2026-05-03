# MoveMate

> **Mobile micro-activity coach for desk workers and recovery-focused users.**
> Built for the **PhysTech** hackathon — a one-handed companion that nudges
> you to move, tracks how you feel, and adapts a 7-day plan around your real
> body signals: pain, sleep, energy, and posture.

[![Flutter](https://img.shields.io/badge/Flutter-3.11%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11%2B-0175C2?logo=dart)](https://dart.dev)
[![Tests](https://img.shields.io/badge/tests-29%20passing-2EB872)](#testing)
[![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android)](https://android.com)

---

## What it does

MoveMate is a **physiotherapy-grade micro-coach**. Most movement apps push you
toward 30-minute workouts; MoveMate is built for the office worker whose ideal
session is **two minutes**. The whole interaction model is "tap once, follow a
gentle voice, get back to your day."

It does three things really well:

1. **Tracks the signals that matter** — daily pain (per body area), sleep
   hours and quality, energy, mood, hydration, posture, and movement history.
2. **Builds a daily and 7-day plan that responds to those signals** — when
   you flag lower-back pain at 7/10, the plan rearranges. When you slept five
   hours, it swaps cardio for breath. When your shoulders haven't been
   touched in a week, it surfaces a shoulder-focused flow.
3. **Coaches you through every session by voice** — TTS-led exercises with
   per-step prompts, tuned by a personality setting (Calm / Upbeat / Strict).

Everything works **offline** with `shared_preferences`. No cloud, no
account.

---

## Feature grid

### 🧠 Smart layer (algorithms)
- **Adaptive 7-day plan** — generates a personalized week using profile, body
  coverage, hot pain areas, latest sleep, and energy
- **Recommender** — picks the next session based on time of day, recent
  history, daily-goal status, energy, and skipped categories
- **Smart Coach** — surfaces 4 contextual lines per day, prioritised by
  signal strength
- **Moment of Pride** — ranked picker that surfaces the user's best recent
  signal (pain drop > streak > week growth > milestone > mood lift > variety
  > comeback) as a celebration hero on Home
- **What's Working** — pure-function picker that scans the last 7–14 days
  for positive observations (active-day rhythm, pain trending down, mood
  lift, variety, week-over-week growth, morning energy spike) and returns
  up to three for a green Home card
- **Wellness Score** — composite index (Streak / Variety / Volume / Today)
  with a week-over-week delta
- **Movement DNA + Energy Hours + Body Coverage** — analytics derived from
  raw session history
- **Personal Records** — longest streak, longest session, best day, totals,
  top focus, active hour window

### 🏃 Active sessions (TTS-guided)
- **Movement sessions** — exercise-by-exercise timer with voice prompts and
  mid-session mood capture
- **Breathing room** — Box · 4-7-8 · Triangle · Coherent breath patterns
  with a pulsing focal circle
- **Breathing wind-down** — automatic 4-cycle box-breathing modal after
  cardio or any session ≥ 5 min, with travelling-dot box visualization
- **Focus mode** — Pomodoro block with built-in mid-block movement nudge
- **Eye Break (20-20-20)** — 30-second three-phase eye-rest
- **Walk Break** — 1 / 2 / 5-min standing walk with TTS cues
- **Mindful Moment (5-4-3-2-1)** — sensory grounding exercise
- **Posture Check** — 5-question self-check with a tailored 3-min follow-up
- **Body Tension Map** — pick sore spots; the app builds a session
  prioritising exercises that overlap them
- **Custom builder** — pick any exercises, set durations, save and run

### 📓 Journals
- **Pain Journal** — per-body-area pain (0–10) with an **interactive body
  heatmap** (front-view silhouette that tints by pain level) plus 14-day
  sparkline charts; drives the adaptive plan + coach
- **Pain report share image** — one-tap render of a 1080×1920 PNG card
  summarising 30-day per-area trends, biggest improvement, hottest area,
  and days logged — shareable straight to a physiotherapist
- **Sleep journal** — last night's hours and 1–5 quality, surfaces 7-day avg
- **Energy check-in** — quick 1–5 emoji tap that influences recommendations
- **Mood + notes** — captured per session
- **Mood quick-log on Home** — standalone 5-emoji bar (😞 😕 😐 🙂 😄) that
  logs how you feel right now without starting a session; auto-collapses for
  4 hours after a fresh log, expands again when stale. With ≥ 3 check-ins
  in the last 7 days, an inline mini line-chart shows the trend
- **Mood line chart** — smooth 14-session area chart on Progress with green
  fill above the zero baseline and red fill below
- **Hydration** — daily glass goal with a single-tap pill
- **Daily challenge + daily mantra** — generated from the date

### 🏆 Engagement
- **Streak with freezes** — protection days earned every 7-day milestone;
  evening rescue banner if today is empty
- **18 achievements** with a confetti-firing celebration dialog (pulsing
  trophy, gradient backdrop, per-badge bounce-in animation) and **per-badge
  progress bars** showing how close you are to locked ones (e.g. "5/7 days",
  "120/200 min")
- **Daily goal celebration** — when a session crosses your daily-minutes
  goal, a green confetti dialog fires once per day
- **Streak milestone celebrations** — dedicated dialog at 7 / 14 / 30 / 60 /
  100 / 200 / 365 day milestones
- **Weekly review** — Monday auto-popup summarising the prior week
- **Weekly recap share image** — 1080×1920 portrait recap card (totals,
  day-by-day bar chart, streak, top focus, mood) shareable from Progress

### 🏠 Home dashboard
- **Daily progress ring** in the header — animated circular ring around the
  app icon showing today's minutes vs daily goal as a percentage; turns
  green with a checkmark + glow when the goal is hit
- **Quick action chips row** — horizontally scrollable colored pills under
  the header (Pain · Eye break · Walk · Breathe · Mindful) for one-tap
  navigation to the most-used tools
- **Hot pain alert banner** — gradient red-to-orange banner that surfaces
  whenever `storage.hotPainAreas()` reports anything ≥ 4/10. Shows the most
  painful area with a "Soothe" CTA that builds a tailored 3-minute relief
  session via `ExerciseLibrary.buildQuickPlanForArea`. Includes an inline
  7-day mini-sparkline and a dynamic blurb (Trending down · Climbing ·
  Steady) so the trend is readable at a glance
- **Yesterday recap card** — compact inline card between Today's Plan and
  Recommended showing yesterday's minutes, session count, top category and
  mood-delta chip; only appears when yesterday had at least one session
- **Moment of Pride hero** — celebratory card that picks the user's best
  recent signal and presents it with a per-kind gradient
- **What's Working card** — green/teal panel listing 1–3 positive
  observations from the last week (active days, pain trending down, mood
  lift, variety, +min vs last week, morning energy) — hides cleanly when
  there's nothing celebratory to say

### 📊 Progress visualisations
- **30-day daily-minutes heatmap** — classic month grid
- **90-day consistency heatmap** — GitHub-style 13-week × 7-day grid with
  active-day count, total minutes, and longest streak callout
- **Body coverage radar** — hexagonal CustomPainter visualising minutes per
  body area (neck/shoulders/back/core/hips/legs)

### 🧰 Wellness tooling and quality of life
- **6-tile wellness strip** — Eye, Walk, Posture, Tension, Mindful, Sleep,
  Pain — horizontally scrollable
- **Quiet hours** — silence reminders during a window that wraps past
  midnight
- **Test notification button** — preview what a real reminder looks like
  before relying on the schedule
- **Voice personality preview** — tap-to-hear button next to each Coach
  option in Settings (Calm / Upbeat / Strict) that speaks a sample line
  using that profile's rate + pitch so users can pick by ear
- **Backup / export** — share a JSON dump of all settings, sessions, and
  logs via the system share sheet
- **Demo seeder** — Settings tile that loads a 30-day realistic snapshot
  (sessions, healing back-pain trend, sleep, energy, hydration, posture)
  for instant demos and screenshots
- **Onboarding pain pre-tag** — fourth onboarding page lets users tap any
  achy areas (cycles mild → moderate → sharp → cleared) so the adaptive
  plan personalizes from session zero
- **Branded splash** — gradient background + vector M monogram, with light
  and dark variants
- **Light / dark / auto theme**, configurable coach voice personality,
  hydration & daily-minutes goals

### 📱 Native Android integration
- **App shortcuts** — long-press the launcher icon for instant access to
  Pain · Stretch · Breathe (intent-filters in `AndroidManifest.xml`,
  `MethodChannel` plumbing in `MainActivity.kt`, Dart-side routing via
  `FadeThroughRoute` in `main.dart`)
- **System notifications** — TZ-aware scheduling, channel + boot receiver
  registration, quiet-hours filter

---

## Tech stack

| Layer | Tech |
|---|---|
| UI | Flutter (Dart 3.11+), Material 3, custom transitions |
| State | Plain `Storage` wrapper around `shared_preferences` (no provider/bloc — keeps the surface tiny and testable) |
| Voice | `flutter_tts` with a per-personality rate / pitch profile |
| Notifications | `flutter_local_notifications` + `timezone` + `flutter_timezone`, with quiet-hours filtering |
| Sharing | `share_plus` + `path_provider` for share-card PNGs and JSON backups |
| Effects | `confetti` for streak / goal / achievement celebrations |
| Native | Kotlin `MethodChannel` for app shortcuts |
| i18n | `intl` for date formatting |

No backend, no auth, no analytics SDK. Single-binary APK.

---

## Architecture

```
┌──────────────────────────────────────────┐
│  4-tab nav: Home · Tools · Progress · ⚙ │
└──────────────────────────────────────────┘
                    ↓
   ┌────────────┐ ┌────────────┐ ┌──────────────┐
   │  Screens   │ │  Algorithms│ │   Storage    │
   ├────────────┤ ├────────────┤ ├──────────────┤
   │ home       │ │ recommender│ │ shared_prefs │
   │ tools      │ │ smart_coach│ │   ↑          │
   │ history    │ │ adaptive_  │ │ Storage      │
   │ settings   │ │   plan     │ │  facade      │
   │ session    │ │ records    │ │              │
   │ pain_log   │ │ wellness_  │ │              │
   │ sleep      │ │   score    │ │              │
   │ ...12 more │ │ moment_of_ │ │              │
   │            │ │   pride    │ │              │
   │            │ │ insights   │ │              │
   └─────┬──────┘ └──────┬─────┘ └──────┬───────┘
         │                │              │
         └────────────────┴──────────────┘
                          │
                ┌─────────▼──────────┐
                │ Models             │
                │ (Exercise, Plan,   │
                │  SessionRecord,    │
                │  BodyArea, ...)    │
                └────────────────────┘

Services:
  · NotificationService  — TZ-aware reminder scheduling, quiet-hours filter,
                           test-now + showTestNow API
  · TtsService           — voice prompts, personality-driven rate/pitch
  · MainActivity.kt      — Android app shortcuts plumbed via MethodChannel
```

The **Storage facade** (`lib/storage.dart`) is the single source of truth.
Every screen reads through it and triggers a `setState` in the shell on
write. There are no streams, controllers, or providers — every render of the
home screen rebuilds from scratch. This was deliberate: the data set is small
(~hundreds of session records), the screens are short-lived, and the overhead
is dwarfed by the productivity gain of having "just a class."

The **algorithm modules** are pure: they take a `Storage` (or a list of
sessions) and return a result. That makes them trivially testable without
any framework setup — see `test/`.

---

## Project structure

```
lib/
  main.dart                  Entry, theme, 4-tab AppShell, shortcut routing
  storage.dart               Single SharedPreferences facade — every key + helper
  models.dart                Exercise, WorkoutPlan, SessionRecord, BodyArea, ...

  # Dashboard + tools
  home_screen.dart           Dashboard (progress ring header, quick actions, hot pain alert,
                             today card, score, pride, coach, plan, yesterday recap, mood log)
  tools_screen.dart          Adaptive plan + wellness strip + categories + plans
  history_screen.dart        Stats, calendar, heatmaps, body coverage radar, mood line,
                             achievements with progress bars, records
  settings_screen.dart       Profile, goals, reminders (with test-fire), quiet hours,
                             voice (with preview), backup

  # Active sessions
  session_screen.dart        Plan-driven workout runner with TTS, mood capture,
                             goal celebration, achievement + streak dialogs
  breathing_screen.dart      Box / 4-7-8 / Triangle / Coherent breath patterns
  wind_down_sheet.dart       4-cycle box-breathing modal after high-effort sessions
  focus_screen.dart          Pomodoro focus + movement nudge
  eye_break_screen.dart      20-20-20 eye-rest
  walk_break_screen.dart     1 / 2 / 5-min standing walk timer
  mindful_screen.dart        5-4-3-2-1 grounding
  posture_check_screen.dart  5-question self-check + tailored follow-up
  tension_screen.dart        Body-area picker → custom session builder
  sleep_screen.dart          Hours + quality entry
  pain_journal_screen.dart   Per-area pain log with body heatmap + 14-day sparkline + share
  body_heatmap.dart          Stack-based front-view body silhouette, tints by pain
  body_coverage_radar.dart   Hexagonal radar of per-area minutes (last 7 days)
  consistency_heatmap.dart   GitHub-style 13-week × 7-day grid
  weekly_plan_screen.dart    Adaptive 7-day plan view
  custom_builder.dart        Pick exercises, set durations
  onboarding_screen.dart     First-run flow (4 pages incl. pain pre-tag)

  # Algorithms (pure, testable)
  recommendations.dart       Recommender — picks the next session
  smart_coach.dart           Coach lines for the dashboard
  adaptive_plan.dart         7-day plan generator
  moment_of_pride.dart       Ranked picker for the celebration hero
  records.dart               Lifetime PersonalRecords
  wellness_score.dart        Composite Streak/Variety/Volume/Today score
  movement_dna.dart          Activity-mix profiling
  energy_hours.dart          When-do-you-move heatmap
  body_coverage.dart         Which areas have you neglected
  insights.dart              Weekly insights aggregation
  daily_challenge.dart       Day-seeded challenge generator
  daily_mantra.dart          Day-seeded mantra
  achievements.dart          18 achievement definitions + check engine + per-badge progress

  # Services
  notification_service.dart  TZ-aware reminders, quiet-hours filter, showTestNow
  tts_service.dart           flutter_tts wrapper with 3 personalities

  # UI helpers + share renderers
  animated_widgets.dart      StaggeredFadeIn cascade
  transitions.dart           FadeThroughRoute
  exercise_library.dart      30+ exercises across 4 categories + featured plans
  share_card.dart            Render shareable PNG of a session
  pain_report_card.dart      30-day pain report PNG (1080×1920) for physiotherapist
  weekly_recap_card.dart     Weekly recap PNG (1080×1920) for social share
  demo_seeder.dart           Generate a 30-day realistic snapshot for demos
  wellness_detail_screen.dart  Score breakdown drill-down
  weekly_review.dart         Monday-morning weekly summary popup
  calendar_screen.dart       Month grid of activity
  mood_picker.dart, note_picker.dart  Reusable session widgets

android/app/src/main/
  AndroidManifest.xml        App shortcuts intent-filters + meta-data
  kotlin/.../MainActivity.kt MethodChannel for shortcut routing
  res/xml/shortcuts.xml      Pain · Stretch · Breathe long-press shortcuts
  res/drawable/              Branded splash gradient + M-monogram vector

test/
  widget_test.dart           Exercise library invariants
  records_test.dart          PersonalRecords algorithms
  adaptive_plan_test.dart    Adaptive 7-day plan generator
  storage_test.dart          Pain / sleep / quiet-hours storage round-trips
  demo_seeder_test.dart      Demo snapshot shape + downstream effects
  moment_of_pride_test.dart  Pride algorithm priority + selection rules

.github/workflows/
  ci.yml                     Flutter analyze + test on push / PR
```

---

## Run it

```powershell
flutter pub get
flutter run -d <android-device-id>
```

Release APK build:

```powershell
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

Install + launch a debug build on a connected phone:

```powershell
flutter install -d <device-id> --debug
adb -s <device-id> shell am start -n pl.movemate.movemate/.MainActivity
```

---

## Testing

```powershell
flutter analyze
flutter test
```

Coverage focuses on the algorithmic core (records, adaptive plan, storage,
demo seeder, moment of pride). The 29 tests in `test/` are framework-light
(`shared_preferences` is mocked via `setMockInitialValues`), run in under
6 seconds, and exercise the interesting branches: streak gaps, day-sums,
plan variation under sleep deficit and pain flags, quiet-hours wrap-around
past midnight, demo seeder produces a healing trend, pride algorithm picks
pain-drop over streak when both qualify, etc.

The included **GitHub Actions workflow** (`.github/workflows/ci.yml`) runs
`flutter analyze --no-fatal-infos` + `flutter test --reporter expanded` on
every push and pull request to `main`.

---

## Design notes

- **No "log your steps" guilt.** The sit-timer pill warns gently after a
  custom interval (default 2 h) but never shouts.
- **Pain comes first.** When the user has flagged real pain, the coach
  surfaces it above streaks and goals — physiotherapy first. The Moment of
  Pride algorithm ranks pain drops above streaks too.
- **Wins, not just nags.** Three celebration moments (achievement, daily
  goal, streak milestone) each have their own dedicated confetti dialog,
  picked to fire independently in the post-session flow.
- **Streak freezes prevent shame spirals.** A 7-day streak earns a freeze.
  Miss a day, and a freeze is consumed silently. The streak survives. The
  rescue banner only appears when freezes are already gone and the day still
  has hours left — it's a backstop, not a guilt trip.
- **Adaptive plan is transparent.** Every day card shows *why* it's there
  ("Targets back + neck", "You haven't worked shoulders recently"). No
  black-box recommendations.
- **Wind-down after intensity.** Cardio sessions and any session ≥ 5 min
  trigger a 4-cycle box-breathing modal before the mood prompt — closing the
  loop on intensity with a calm reset rather than a hard stop.
- **One-tap is the bar.** The Home dashboard is laid out so the most-common
  next actions (start a recommended session, log mood, soothe a hot pain
  area, jump to Pain / Eye / Walk / Breathe / Mindful) are reachable in a
  single tap from the top of the screen.

---

## Roadmap (post-hackathon)

- [ ] Posture detection via on-device ML (`google_mlkit_pose_detection`) —
      camera-driven posture overlay
- [ ] Health Connect integration — pull step count + heart rate
- [ ] Localization — Polish + English language packs
- [ ] Adaptive plan editing — drag-to-rearrange days
- [ ] Multi-page physiotherapist PDF export
- [ ] Apple Health + iOS support

---

Built solo for the **PhysTech** hackathon · v1.0.0
