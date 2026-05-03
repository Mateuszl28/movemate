import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'storage.dart';

/// Browseable journal of every session note the user has written. Searchable,
/// grouped by date, with category accents and mood deltas surfaced inline.
class NotesJournalScreen extends StatefulWidget {
  final Storage storage;
  const NotesJournalScreen({super.key, required this.storage});

  @override
  State<NotesJournalScreen> createState() => _NotesJournalScreenState();
}

class _NotesJournalScreenState extends State<NotesJournalScreen> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final all = widget.storage.sessions
        .where((s) => s.note != null && s.note!.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final q = _query.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all
            .where((s) =>
                s.note!.toLowerCase().contains(q) ||
                s.planTitle.toLowerCase().contains(q) ||
                s.category.label.toLowerCase().contains(q))
            .toList();

    final grouped = <String, List<SessionRecord>>{};
    for (final s in filtered) {
      final key = _dayHeader(s.completedAt);
      grouped.putIfAbsent(key, () => []).add(s);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes journal'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search notes…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: scheme.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _query.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(hasNotes: all.isNotEmpty, query: q)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: grouped.length,
                      itemBuilder: (_, i) {
                        final key = grouped.keys.elementAt(i);
                        final items = grouped[key]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                  4, i == 0 ? 4 : 14, 4, 6),
                              child: Text(key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6)),
                            ),
                            for (final s in items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _NoteTile(session: s, query: q),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayHeader(DateTime d) {
    final today = DateTime.now();
    final diff = DateTime(today.year, today.month, today.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE', 'en_US').format(d);
    return DateFormat('EEEE · d MMM', 'en_US').format(d);
  }
}

class _NoteTile extends StatelessWidget {
  final SessionRecord session;
  final String query;
  const _NoteTile({required this.session, required this.query});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = session.category.accent;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accent, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(session.category.icon, size: 14, color: accent),
                    const SizedBox(width: 4),
                    Text(
                      session.category.label,
                      style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  session.planTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              if (session.moodDelta != null) ...[
                const SizedBox(width: 6),
                _MoodChip(delta: session.moodDelta!),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _HighlightedText(text: session.note!, query: query),
          const SizedBox(height: 6),
          Text(
            DateFormat('HH:mm · ${(session.seconds / 60).round()} min')
                .format(session.completedAt),
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  final int delta;
  const _MoodChip({required this.delta});

  @override
  Widget build(BuildContext context) {
    final positive = delta > 0;
    final neutral = delta == 0;
    final color = positive
        ? const Color(0xFF2EB872)
        : neutral
            ? Colors.grey
            : const Color(0xFFE57373);
    final label = positive
        ? '+$delta'
        : neutral
            ? '±0'
            : '$delta';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label mood',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  const _HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.4,
          fontStyle: FontStyle.italic,
        );
    if (query.isEmpty) return Text(text, style: base);
    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(query, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.normal,
        ),
      ));
      start = idx + query.length;
    }
    return RichText(
      text: TextSpan(style: base, children: spans),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasNotes;
  final String query;
  const _EmptyState({required this.hasNotes, required this.query});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📝', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              !hasNotes
                  ? 'No notes yet'
                  : 'No notes match "$query"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              !hasNotes
                  ? 'Add a note at the end of any session — they\'ll show up here as a journal you can scan back through.'
                  : 'Try a different word or clear the search.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
