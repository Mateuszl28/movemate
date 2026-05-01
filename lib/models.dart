import 'package:flutter/material.dart';

enum ExerciseCategory { stretch, mobility, breath, cardio }

extension ExerciseCategoryX on ExerciseCategory {
  String get label {
    switch (this) {
      case ExerciseCategory.stretch:
        return 'Stretching';
      case ExerciseCategory.mobility:
        return 'Mobility';
      case ExerciseCategory.breath:
        return 'Breathing';
      case ExerciseCategory.cardio:
        return 'Cardio';
    }
  }

  IconData get icon {
    switch (this) {
      case ExerciseCategory.stretch:
        return Icons.self_improvement;
      case ExerciseCategory.mobility:
        return Icons.accessibility_new;
      case ExerciseCategory.breath:
        return Icons.air;
      case ExerciseCategory.cardio:
        return Icons.directions_run;
    }
  }

  Color get accent {
    switch (this) {
      case ExerciseCategory.stretch:
        return const Color(0xFF7BC67E);
      case ExerciseCategory.mobility:
        return const Color(0xFFFFB74D);
      case ExerciseCategory.breath:
        return const Color(0xFF64B5F6);
      case ExerciseCategory.cardio:
        return const Color(0xFFE57373);
    }
  }
}

enum ActivityProfile { sedentary, active, recovery }

extension ActivityProfileX on ActivityProfile {
  String get label {
    switch (this) {
      case ActivityProfile.sedentary:
        return 'Desk-bound';
      case ActivityProfile.active:
        return 'Active';
      case ActivityProfile.recovery:
        return 'Recovery';
    }
  }

  String get description {
    switch (this) {
      case ActivityProfile.sedentary:
        return 'You work at a desk — short mobility and stretching breaks.';
      case ActivityProfile.active:
        return 'You move a lot — quick cardio and stability bursts.';
      case ActivityProfile.recovery:
        return 'Lighter breathing and gentle mobility sessions.';
    }
  }
}

class Exercise {
  final String id;
  final String name;
  final String instruction;
  final int seconds;
  final ExerciseCategory category;
  final String emoji;

  const Exercise({
    required this.id,
    required this.name,
    required this.instruction,
    required this.seconds,
    required this.category,
    required this.emoji,
  });
}

class WorkoutPlan {
  final String title;
  final String subtitle;
  final ExerciseCategory primaryCategory;
  final List<Exercise> exercises;

  const WorkoutPlan({
    required this.title,
    required this.subtitle,
    required this.primaryCategory,
    required this.exercises,
  });

  int get totalSeconds =>
      exercises.fold<int>(0, (sum, e) => sum + e.seconds);

  String get formattedDuration {
    final minutes = totalSeconds ~/ 60;
    final remainder = totalSeconds % 60;
    if (remainder == 0) return '$minutes min';
    return '$minutes:${remainder.toString().padLeft(2, '0')} min';
  }
}

class SessionRecord {
  final DateTime completedAt;
  final String planTitle;
  final ExerciseCategory category;
  final int seconds;

  SessionRecord({
    required this.completedAt,
    required this.planTitle,
    required this.category,
    required this.seconds,
  });

  Map<String, dynamic> toJson() => {
        't': completedAt.toIso8601String(),
        'p': planTitle,
        'c': category.index,
        's': seconds,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        completedAt: DateTime.parse(json['t'] as String),
        planTitle: json['p'] as String,
        category: ExerciseCategory.values[json['c'] as int],
        seconds: json['s'] as int,
      );
}
