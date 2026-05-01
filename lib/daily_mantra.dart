import 'models.dart';

class Mantra {
  final String text;
  final String emoji;
  const Mantra(this.emoji, this.text);
}

class DailyMantra {
  static const _shared = <Mantra>[
    Mantra('🌿', 'Small moves, every day, beat heroic Mondays.'),
    Mantra('🫁', 'A long exhale is the cheapest reset there is.'),
    Mantra('🦴', 'Motion is lotion — the joints want to be used.'),
    Mantra('⏱️', '120 seconds is enough. The hard part is starting.'),
    Mantra('🎯', "You don't have to be good. You have to be back."),
    Mantra('🧠', 'A moving body wakes a foggy mind.'),
    Mantra('🌊', 'Consistency beats intensity. Always.'),
    Mantra('🌱', 'Today\'s session is tomorrow\'s baseline.'),
    Mantra('🪶', 'Light effort, often, beats hard effort, never.'),
  ];

  static const _sedentary = <Mantra>[
    Mantra('💺', 'Your chair is not your friend. Stand and reset.'),
    Mantra('🦒', 'Lift the head, drop the shoulders, breathe deep.'),
    Mantra('🌬️', 'Two minutes of mobility now buys you a clear afternoon.'),
    Mantra('🪑', 'Sitting is the new smoking — and you have the antidote.'),
  ];

  static const _active = <Mantra>[
    Mantra('🔥', 'Strong this week, mobile next week, unbreakable next year.'),
    Mantra('⚡', 'Intensity is fuel — recovery is the engine.'),
    Mantra('🏃', 'Train hard, breathe deeper, sleep longer.'),
    Mantra('🎯', 'Sharpen the tool before you swing harder.'),
  ];

  static const _recovery = <Mantra>[
    Mantra('🪷', 'Slow is smooth, smooth is healing.'),
    Mantra('🕊️', 'Healing is also movement — gentle, deliberate, brave.'),
    Mantra('🌙', 'Rest is not the opposite of progress.'),
    Mantra('💧', 'Soft tissue, soft breath, steady mind.'),
  ];

  static Mantra forDate(DateTime date, {ActivityProfile? profile}) {
    final pool = <Mantra>[
      ..._shared,
      ...switch (profile) {
        ActivityProfile.sedentary => _sedentary,
        ActivityProfile.active => _active,
        ActivityProfile.recovery => _recovery,
        null => _shared,
      },
    ];
    final seed = date.year * 1000 + date.month * 50 + date.day;
    return pool[seed % pool.length];
  }
}
