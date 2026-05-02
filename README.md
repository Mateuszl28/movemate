# MoveMate

A mobile micro-activity coach — Flutter app built for the **PhysTech** hackathon.

MoveMate nudges you to take short movement breaks during the day, guides you through exercise and breathing sessions, and tracks your mood, wellbeing, and progress along the way. Designed for Android, works offline.

## Features

- **Movement and breathing sessions** — short exercises with voice guidance (TTS), guided breathing, focus screen
- **Smart coach** — recommendations tailored to time of day, mood, and history (`smart_coach.dart`, `recommendations.dart`)
- **Notifications** — configurable movement reminders at chosen intervals (`flutter_local_notifications` + `timezone`)
- **Streak with freezes** — daily streak system with protection days
- **Wellness Score, Movement DNA, Energy Hours** — wellbeing indicators, activity profile, and an energy-by-hour map
- **Eye Break (20-20-20)** — guided 30-second three-phase eye-rest with TTS prompts (`eye_break_screen.dart`)
- **Walk Break** — 1 / 2 / 5-min standing-and-walking timer with TTS cues; logs as cardio (`walk_break_screen.dart`)
- **Posture Check** — 5-question interactive self-check with score, weak-spot tags, and a tailored 3-min follow-up flow (`posture_check_screen.dart`)
- **Hydration tracking** — daily glass goal with a home-screen pill
- **Energy check-in** — quick 1-5 emoji tap that feeds the Smart Coach and recommender
- **Quiet hours** — configurable window that silences reminder notifications (wraps past midnight)
- **Mood & notes** — quick mood picker, per-session notes
- **Body coverage** — visualization of which body parts were trained
- **Achievements, daily challenge, daily mantra, weekly review**
- **History calendar**, export / share summaries (share card)
- **Onboarding**, light/dark theme, settings

## Tech stack

- **Flutter** (Dart SDK `^3.11.0`), Material 3
- **shared_preferences** — local state persistence
- **flutter_tts** — speech synthesis
- **flutter_local_notifications** + **timezone** + **flutter_timezone** — scheduled reminders
- **intl**, **confetti**, **share_plus**, **path_provider**

## Getting started

Requirements: Flutter SDK 3.11+, Android SDK, a device or emulator (ADB).

```powershell
flutter pub get
flutter run
```

Release APK build:

```powershell
flutter build apk --release
```

## Project structure

All app code lives in `lib/`:

| File | Role |
|---|---|
| `main.dart` | Entry point, theming, onboarding ↔ app routing |
| `home_screen.dart` | Main dashboard screen |
| `session_screen.dart`, `breathing_screen.dart`, `focus_screen.dart`, `eye_break_screen.dart`, `walk_break_screen.dart`, `posture_check_screen.dart` | Active sessions and wellness tools |
| `exercise_library.dart`, `custom_builder.dart` | Exercise library and custom builder |
| `smart_coach.dart`, `recommendations.dart` | Recommendation logic |
| `storage.dart`, `models.dart` | Persistence and data models |
| `notification_service.dart`, `tts_service.dart` | Notifications, speech |
| `wellness_score.dart`, `movement_dna.dart`, `energy_hours.dart`, `body_coverage.dart`, `insights.dart` | Analytics and indicators |
| `achievements.dart`, `daily_challenge.dart`, `daily_mantra.dart`, `weekly_review.dart` | Gamification and summaries |
| `history_screen.dart`, `calendar_screen.dart` | Session history |
| `settings_screen.dart`, `onboarding_screen.dart` | Settings and first run |
| `mood_picker.dart`, `note_picker.dart`, `share_card.dart`, `transitions.dart`, `wellness_detail_screen.dart` | UI components |

## Version

`1.0.0+1` (`pubspec.yaml`). Dev tags in git history: `V.0.0.0.0.0.1.x`.
