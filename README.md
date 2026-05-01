# MoveMate

Mobilny coach mikroaktywności fizycznej — aplikacja Flutter zbudowana na hackathon **PhysTech**.

MoveMate przypomina o krótkich przerwach na ruch w ciągu dnia, prowadzi przez sesje ćwiczeń i oddechu, a przy okazji śledzi nastrój, samopoczucie i postępy. Zaprojektowany pod Androida, działa offline.

## Co potrafi

- **Sesje ruchu i oddechu** — krótkie ćwiczenia z prowadzeniem głosowym (TTS), prowadzony oddech, ekran skupienia
- **Inteligentny coach** — rekomendacje dopasowane do pory dnia, nastroju i historii (`smart_coach.dart`, `recommendations.dart`)
- **Powiadomienia** — konfigurowalne przypomnienia o ruchu w wybranych odstępach (`flutter_local_notifications` + `timezone`)
- **Streak z „freezami"** — system serii dziennej z dniami ochronnymi
- **Wellness Score, Movement DNA, Energy Hours** — wskaźniki samopoczucia, profil aktywności i mapa godzin energii
- **Mood & notatki** — szybki wybór nastroju, notatki do sesji
- **Body coverage** — wizualizacja, które partie ciała były pracowane
- **Achievementy, dzienne wyzwanie, mantra dnia, weekly review**
- **Kalendarz historii**, eksport / udostępnianie podsumowań (share card)
- **Onboarding**, motyw jasny/ciemny, ustawienia

## Stos technologiczny

- **Flutter** (Dart SDK `^3.11.0`), Material 3
- **shared_preferences** — lokalna pamięć stanu
- **flutter_tts** — synteza mowy
- **flutter_local_notifications** + **timezone** + **flutter_timezone** — zaplanowane przypomnienia
- **intl**, **confetti**, **share_plus**, **path_provider**

## Uruchomienie

Wymagania: Flutter SDK 3.11+, Android SDK, urządzenie / emulator (ADB).

```powershell
flutter pub get
flutter run
```

Build APK release:

```powershell
flutter build apk --release
```

## Struktura projektu

Cały kod aplikacji znajduje się w `lib/`:

| Plik | Rola |
|---|---|
| `main.dart` | Punkt wejścia, motyw, routing onboarding ↔ aplikacja |
| `home_screen.dart` | Główny ekran z dashboardem |
| `session_screen.dart`, `breathing_screen.dart`, `focus_screen.dart` | Sesje aktywne |
| `exercise_library.dart`, `custom_builder.dart` | Biblioteka i kreator ćwiczeń |
| `smart_coach.dart`, `recommendations.dart` | Logika rekomendacji |
| `storage.dart`, `models.dart` | Persystencja i modele danych |
| `notification_service.dart`, `tts_service.dart` | Powiadomienia, mowa |
| `wellness_score.dart`, `movement_dna.dart`, `energy_hours.dart`, `body_coverage.dart`, `insights.dart` | Analityka i wskaźniki |
| `achievements.dart`, `daily_challenge.dart`, `daily_mantra.dart`, `weekly_review.dart` | Grywalizacja i podsumowania |
| `history_screen.dart`, `calendar_screen.dart` | Historia sesji |
| `settings_screen.dart`, `onboarding_screen.dart` | Ustawienia i pierwsze uruchomienie |
| `mood_picker.dart`, `note_picker.dart`, `share_card.dart`, `transitions.dart`, `wellness_detail_screen.dart` | UI komponenty |

## Wersja

`1.0.0+1` (`pubspec.yaml`). Tagi developerskie w historii git: `V.0.0.0.0.0.1.x`.
