# MoveMate

> **Mobile micro-activity coach for desk workers and recovery-focused users.**
> Built for the **PhysTech** hackathon — a one-handed companion that nudges
> you to move, tracks how you feel, and adapts a 7-day plan around your real
> body signals: pain, sleep, energy, and posture.

[![Flutter](https://img.shields.io/badge/Flutter-3.11%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11%2B-0175C2?logo=dart)](https://dart.dev)
[![Tests](https://img.shields.io/badge/tests-25%20passing-2EB872)](#testing)
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
- **Sleep journal** — last night's hours and 1–5 quality, surfaces 7-day avg
- **Energy check-in** — quick 1–5 emoji tap that influences recommendations
- **Mood + notes** — captured per session
- **Hydration** — daily glass goal with a single-tap pill
- **Daily challenge + daily mantra** — generated from the date

### 🏆 Engagement
- **Streak with freezes** — protection days earned every 7-day milestone;
  evening rescue banner if today is empty
- **18 achievements** across sessions, streaks, eye breaks, posture, sleep,
  mindfulness
- **Weekly review** — Monday auto-popup summarising the prior week

### 🧰 Wellness tooling and quality of life
- **6-tile wellness strip** — Eye, Walk, Posture, Tension, Mindful, Sleep,
  Pain — horizontally scrollable
- **Quiet hours** — silence reminders during a window that wraps past
  midnight
- **Backup / export** — share a JSON dump of all settings, sessions, and
  logs via the system share sheet
- **Demo seeder** — Settings tile that loads a 30-day realistic snapshot
  (sessions, healing back-pain trend, sleep, energy, hydration, posture)
  for instant demos and screenshots
- **Light / dark / auto theme**, configurable coach voice personality,
  hydration & daily-minutes goals

---

## Tech stack

| Layer | Tech |
|---|---|
| UI | Flutter (Dart 3.11+), Material 3, custom transitions |
| State | Plain `Storage` wrapper around `shared_preferences` (no provider/bloc — keeps the surface tiny and testable) |
| Voice | `flutter_tts` with a per-personality rate / pitch profile |
| Notifications | `flutter_local_notifications` + `timezone` + `flutter_timezone`, with quiet-hours filtering |
| Sharing | `share_plus` + `path_provider` for share-card PNGs and JSON backups |
| Effects | `confetti` for streak celebrations |
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
   │ ...12 more │ │ insights   │ │              │
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
  · NotificationService  — TZ-aware reminder scheduling, quiet-hours filter
  · TtsService           — voice prompts, personality-driven rate/pitch
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
  main.dart                  Entry, theme, 4-tab AppShell
  storage.dart               Single SharedPreferences facade — every key + helper
  models.dart                Exercise, WorkoutPlan, SessionRecord, BodyArea, ...

  # Dashboard + tools
  home_screen.dart           Daily dashboard (TodayCard, score, coach, recommended)
  tools_screen.dart          Adaptive plan + wellness strip + categories + plans
  history_screen.dart        Stats, calendar, body coverage, records, achievements
  settings_screen.dart       Profile, goals, reminders, quiet hours, voice, backup

  # Active sessions
  session_screen.dart        Plan-driven workout runner with TTS + mood capture
  breathing_screen.dart      Box / 4-7-8 / Triangle / Coherent breath patterns
  focus_screen.dart          Pomodoro focus + movement nudge
  eye_break_screen.dart      20-20-20 eye-rest
  walk_break_screen.dart     1 / 2 / 5-min standing walk timer
  mindful_screen.dart        5-4-3-2-1 grounding
  posture_check_screen.dart  5-question self-check + tailored follow-up
  tension_screen.dart        Body-area picker → custom session builder
  sleep_screen.dart          Hours + quality entry
  pain_journal_screen.dart   Per-area pain log with body heatmap + 14-day sparkline
  body_heatmap.dart          Stack-based front-view body silhouette, tints by pain
  weekly_plan_screen.dart    Adaptive 7-day plan view
  custom_builder.dart        Pick exercises, set durations
  onboarding_screen.dart     First-run flow

  # Algorithms (pure, testable)
  recommendations.dart       Recommender — picks the next session
  smart_coach.dart           Coach lines for the dashboard
  adaptive_plan.dart         7-day plan generator
  records.dart               Lifetime PersonalRecords
  wellness_score.dart        Composite Streak/Variety/Volume/Today score
  movement_dna.dart          Activity-mix profiling
  energy_hours.dart          When-do-you-move heatmap
  body_coverage.dart         Which areas have you neglected
  insights.dart              Weekly insights aggregation
  daily_challenge.dart       Day-seeded challenge generator
  daily_mantra.dart          Day-seeded mantra
  achievements.dart          18 achievement definitions + check engine

  # Services
  notification_service.dart  TZ-aware reminders + quiet-hours filter
  tts_service.dart           flutter_tts wrapper with 3 personalities

  # UI helpers
  animated_widgets.dart      StaggeredFadeIn cascade
  transitions.dart           FadeThroughRoute
  exercise_library.dart      30+ exercises across 4 categories + featured plans
  share_card.dart            Render shareable PNG of a session
  demo_seeder.dart           Generate a 30-day realistic snapshot for demos
  wellness_detail_screen.dart  Score breakdown drill-down
  weekly_review.dart         Monday-morning weekly summary popup
  calendar_screen.dart       Month grid of activity
  mood_picker.dart, note_picker.dart  Reusable session widgets

test/
  widget_test.dart           Exercise library invariants
  records_test.dart          PersonalRecords algorithms
  adaptive_plan_test.dart    Adaptive 7-day plan generator
  storage_test.dart          Pain / sleep / quiet-hours storage round-trips
  demo_seeder_test.dart      Demo snapshot shape + downstream effects

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
demo seeder). The 25 tests in `test/` are framework-light
(`shared_preferences` is mocked via `setMockInitialValues`), run in under
6 seconds, and exercise the interesting branches: streak gaps, day-sums,
plan variation under sleep deficit and pain flags, quiet-hours wrap-around
past midnight, demo seeder produces a healing trend, etc.

The included **GitHub Actions workflow** (`.github/workflows/ci.yml`) runs
`flutter analyze --no-fatal-infos` + `flutter test --reporter expanded` on
every push and pull request to `main`.

---

## Design notes

- **No "log your steps" guilt.** The sit-timer pill warns gently after a
  custom interval (default 2 h) but never shouts.
- **Pain comes first in the coach.** When the user has flagged real pain,
  the coach surfaces it above streaks and goals — physiotherapy first.
- **Streak freezes prevent shame spirals.** A 7-day streak earns a freeze.
  Miss a day, and a freeze is consumed silently. The streak survives. The
  rescue banner only appears when freezes are already gone and the day still
  has hours left — it's a backstop, not a guilt trip.
- **Adaptive plan is transparent.** Every day card shows *why* it's there
  ("Targets back + neck", "You haven't worked shoulders recently"). No
  black-box recommendations.

---

## Roadmap (post-hackathon)

- [ ] Posture detection via on-device ML (`google_mlkit_pose_detection`) —
      camera-driven posture overlay
- [ ] Health Connect integration — pull step count + heart rate
- [ ] Localization — Polish + English language packs
- [ ] Adaptive plan editing — drag-to-rearrange days
- [ ] Pain trend report PDF export
- [ ] Apple Health + iOS support

---

Built solo for the **PhysTech** hackathon · v1.0.0
