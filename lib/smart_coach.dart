import 'body_coverage.dart';
import 'insights.dart';
import 'models.dart';
import 'storage.dart';

class CoachLine {
  final String text;
  final String emoji;
  const CoachLine({required this.text, required this.emoji});
}

class SmartCoach {
  /// Builds 2-4 short coach lines for the home screen, oriented around
  /// today + the trailing 7 days. Lines are ordered by relevance.
  static List<CoachLine> dailySummary(Storage storage, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final sessions = storage.sessions;
    final goal = storage.dailyGoalMinutes;
    final todayMin = storage.todayMinutes;
    final streak = storage.currentStreak;
    final freezes = storage.freezesAvailable;
    final insights = WeeklyInsights.from(sessions);
    final coverage = BodyCoverage.lastWeek(sessions, clock);

    final lines = <CoachLine>[];

    // Streak vibe.
    if (streak >= 14) {
      lines.add(CoachLine(
          emoji: '🔥',
          text: 'You\'re on a $streak-day streak — protected by $freezes freeze${freezes == 1 ? "" : "s"}.'));
    } else if (streak >= 3) {
      lines.add(CoachLine(
          emoji: '🔥',
          text:
              'Day $streak in a row. Tiny moves, big momentum.'));
    } else if (streak == 0 && sessions.isNotEmpty) {
      lines.add(const CoachLine(
          emoji: '🌱',
          text: 'A short session today restarts your streak.'));
    }

    // Today goal status.
    if (goal > 0) {
      if (todayMin >= goal) {
        lines.add(CoachLine(
            emoji: '✅',
            text:
                'Daily goal already met — anything more is a bonus today.'));
      } else if (todayMin > 0) {
        lines.add(CoachLine(
            emoji: '🎯',
            text:
                '$todayMin / $goal min today — ${goal - todayMin} min closes the loop.'));
      } else {
        lines.add(CoachLine(
            emoji: '🎯',
            text:
                'Nothing logged today — a 2-minute reset gets you on the board.'));
      }
    }

    // Mood signal.
    final moodAvg = insights.averageMoodDelta;
    if (moodAvg != null && insights.moodTrackedSessions >= 2) {
      if (moodAvg >= 1.0) {
        lines.add(CoachLine(
            emoji: '✨',
            text:
                'Movement has lifted your mood by +${moodAvg.toStringAsFixed(1)} on average — keep the rhythm.'));
      } else if (moodAvg <= -0.5) {
        lines.add(CoachLine(
            emoji: '💭',
            text:
                'Mood dipped on average — try a calmer breathing or wind-down.'));
      }
    }

    // Variety / category gaps.
    final missed = insights.missedCategoriesThisWeek;
    if (missed.length == 1) {
      lines.add(CoachLine(
          emoji: '🎨',
          text:
              'No ${missed.first.label.toLowerCase()} this week — a quick session rounds you out.'));
    } else if (missed.length >= 2 && missed.length < 4) {
      final names = missed
          .take(2)
          .map((c) => c.label.toLowerCase())
          .join(' and ');
      lines.add(CoachLine(
          emoji: '🎨',
          text: 'Missed this week: $names. Mix it up tomorrow.'));
    }

    // Body coverage gap (most useful when at least some movement happened).
    if (coverage.totalSeconds > 0 && coverage.neglected.isNotEmpty) {
      final spotlight = coverage.neglected.first;
      lines.add(CoachLine(
          emoji: spotlight.emoji,
          text:
              '${spotlight.label} hasn\'t had attention this week — slip in a quick segment.'));
    }

    // Eye-strain nudge: working hours, no eye breaks today.
    final eyeToday = storage.eyeBreaksToday;
    final hour = clock.hour;
    if (eyeToday == 0 && hour >= 10 && hour <= 18) {
      lines.add(const CoachLine(
          emoji: '👀',
          text:
              'No eye breaks yet — a 30-second 20-20-20 keeps your focus sharp.'));
    } else if (eyeToday >= 3) {
      lines.add(CoachLine(
          emoji: '🔭',
          text:
              '$eyeToday eye breaks logged today — your retinas thank you.'));
    }

    // Posture signal.
    final posture = storage.latestPostureScore;
    if (posture != null && posture < 60) {
      lines.add(const CoachLine(
          emoji: '🪑',
          text:
              'Your last posture check flagged drift — re-run it after a quick mobility flow.'));
    } else if (posture == null && sessions.length >= 3) {
      lines.add(const CoachLine(
          emoji: '🪞',
          text:
              'Try a 30-second posture check — it tunes your setup before the next focus block.'));
    }

    // Energy check-in signal.
    final energy = storage.latestEnergy;
    final todayKey =
        '${clock.year.toString().padLeft(4, '0')}-${clock.month.toString().padLeft(2, '0')}-${clock.day.toString().padLeft(2, '0')}';
    final energyToday = storage.energyLog[todayKey];
    final hasTodayEnergy = energyToday != null && energyToday.isNotEmpty;
    if (!hasTodayEnergy && hour >= 9 && hour <= 19) {
      lines.add(const CoachLine(
          emoji: '⚡',
          text:
              'Tap an energy level — it sharpens what I recommend next.'));
    } else if (hasTodayEnergy && energy != null) {
      if (energy <= 2) {
        lines.add(const CoachLine(
            emoji: '🌙',
            text:
                'Low energy logged — keep it gentle: breath or slow stretch.'));
      } else if (energy >= 4) {
        lines.add(const CoachLine(
            emoji: '🚀',
            text:
                'High energy logged — perfect window for a cardio burst.'));
      }
    }

    // Sleep signal.
    final sleep = storage.latestSleep;
    if (sleep != null) {
      if (sleep.hours < 6) {
        lines.add(CoachLine(
            emoji: '🌙',
            text:
                'Only ${sleep.hours.toStringAsFixed(1)} h of sleep — favour stretching and breath today.'));
      } else if (sleep.quality <= 2) {
        lines.add(const CoachLine(
            emoji: '☁️',
            text:
                'Last night was rough — a mindful moment can take the edge off.'));
      }
    } else if (hour >= 6 && hour <= 11 && sessions.length >= 2) {
      lines.add(const CoachLine(
          emoji: '🛌',
          text:
              'Log how you slept — it tunes today\'s suggestions to your energy.'));
    }

    // Mindfulness nudge.
    final mindful = storage.mindfulToday;
    if (mindful == 0 && hour >= 13 && hour <= 21) {
      lines.add(const CoachLine(
          emoji: '🧘',
          text:
              'A 1-minute 5-4-3-2-1 grounding fits perfectly between focus blocks.'));
    }

    // Empty-state nudge.
    if (lines.isEmpty) {
      lines.add(const CoachLine(
          emoji: '🌅',
          text:
              'Welcome — start with a 3-minute desk reset to set the tone.'));
    }

    // Keep it tight on home: at most 4 lines.
    return lines.take(4).toList();
  }
}
