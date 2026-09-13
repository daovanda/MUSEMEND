import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/features/checkin/application/reflect_providers.dart';
import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/journals/application/journal_providers.dart';
import 'package:musemend/features/journals/domain/journal_entry.dart';
import 'package:musemend/features/journals/domain/journal_media.dart';
import 'package:musemend/features/journals/domain/journal_calendar.dart';
import 'package:musemend/features/journals/presentation/journal_editor_screen.dart';
import 'package:musemend/features/checkin/presentation/mood_visuals.dart';
import 'package:musemend/features/notifications/application/notification_providers.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({this.requestedEntryId, super.key});

  final String? requestedEntryId;

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  String? _handledEntryId;

  @override
  void didUpdateWidget(covariant JournalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestedEntryId != oldWidget.requestedEntryId) {
      _handledEntryId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    ref.listen(reflectControllerProvider, (previous, next) {
      final previousMood = previous?.value?.today?.mood;
      final nextMood = next.value?.today?.mood;
      if (previousMood != nextMood) {
        ref.invalidate(journalCalendarProvider);
      }
    });
    final entries = ref.watch(journalControllerProvider);
    final calendar = ref.watch(journalCalendarProvider);
    final calendarData = calendar.asData?.value;
    final todayEntry =
        _findTodayEntryInCalendar(calendarData) ??
        _findTodayEntry(entries.asData?.value);
    final todayMood = _findTodayMoodInCalendar(calendarData);
    final requestedEntry = switch (widget.requestedEntryId) {
      final id? => ref.watch(journalEntryProvider(id)),
      null => null,
    };
    requestedEntry?.whenData(_scheduleRequestedEntry);
    return MusePageBackground(
      accent: MuseColors.sky,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reloadAll,
          child: MuseResponsiveList(
            top: 20,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              MuseTopBar(trailing: MusePageBadge(label: strings.navJournal)),
              const SizedBox(height: 4),
              MusePageTagline(strings.journalTagline),
              const SizedBox(height: 28),
              calendar.when(
                loading: () => const _JournalCalendarLoading(),
                error: (_, _) => _JournalError(onRetry: _reloadAll),
                data:
                    (value) => _DailyCalendarSection(
                      calendar: value,
                      hasTodayEntry: todayEntry != null,
                      todayMood: todayMood,
                      onWriteToday:
                          () => _editDaily(
                            context,
                            ref,
                            entry: todayEntry,
                            todayMood: todayMood,
                          ),
                      onOpen:
                          (entry) => _openEntry(
                            context,
                            ref,
                            entry,
                            todayMood: todayMood,
                          ),
                    ),
              ),
              const SizedBox(height: 28),
              MuseSectionLabel(
                strings.futureLetters,
                trailing: IconButton(
                  tooltip: strings.futureLetterWriteNew,
                  onPressed: () => _editLetter(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  color: MuseColors.teal,
                ),
              ),
              const SizedBox(height: 6),
              Text(strings.futureLettersDescription),
              const SizedBox(height: 14),
              entries.when(
                loading: () => const _JournalCalendarLoading(compact: true),
                error: (_, _) => _JournalError(onRetry: _reloadAll),
                data: (items) {
                  final letters = items
                      .where((entry) => entry.kind == JournalKind.futureLetter)
                      .toList(growable: false);
                  if (letters.isEmpty) {
                    return _EmptyFutureLetters(
                      onCreate: () => _editLetter(context, ref),
                    );
                  }
                  return Column(
                    children: [
                      for (final entry in letters)
                        _JournalCard(
                          entry: entry,
                          onTap: () => _openEntry(context, ref, entry),
                          onDelete: () => _delete(context, ref, entry),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reloadAll() async {
    ref.invalidate(journalCalendarProvider);
    await ref.read(journalControllerProvider.notifier).reload();
  }

  DateTime _today() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return DateTime.utc(now.year, now.month, now.day);
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  JournalEntry? _findTodayEntry(List<JournalEntry>? items) {
    if (items == null) return null;
    final today = _today();
    for (final entry in items) {
      if (entry.kind == JournalKind.daily &&
          entry.entryDate != null &&
          _sameDate(entry.entryDate!, today)) {
        return entry;
      }
    }
    return null;
  }

  JournalEntry? _findTodayEntryInCalendar(JournalCalendarData? data) {
    if (data == null) return null;
    for (final month in data.months) {
      for (final day in month.days) {
        if (_sameDate(day.date, data.today)) return day.journal;
      }
    }
    return null;
  }

  Mood? _findTodayMoodInCalendar(JournalCalendarData? data) {
    if (data == null) return null;
    for (final month in data.months) {
      for (final day in month.days) {
        if (_sameDate(day.date, data.today)) return day.checkin?.mood;
      }
    }
    return null;
  }

  void _scheduleRequestedEntry(JournalEntry? entry) {
    final requestedId = widget.requestedEntryId;
    if (requestedId == null || _handledEntryId == requestedId) return;
    _handledEntryId = requestedId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (entry == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).journalEntryNotFound),
          ),
        );
        return;
      }
      _openEntry(context, ref, entry);
    });
  }

  Future<void> _openEntry(
    BuildContext context,
    WidgetRef ref,
    JournalEntry entry, {
    Mood? todayMood,
  }) async {
    if (entry.kind == JournalKind.daily) {
      await _editDaily(context, ref, entry: entry, todayMood: todayMood);
      return;
    }
    if (entry.openedAt == null) {
      final opened = await ref
          .read(journalControllerProvider.notifier)
          .open(entry.id);
      if (!context.mounted || !opened) {
        if (context.mounted) _showFailure(context);
        return;
      }
    }
    if (context.mounted) await _editLetter(context, ref, entry: entry);
  }

  Future<void> _editDaily(
    BuildContext context,
    WidgetRef ref, {
    JournalEntry? entry,
    Mood? todayMood,
  }) async {
    final resolvedTodayMood =
        todayMood ??
        _findTodayMoodInCalendar(
          ref.read(journalCalendarProvider).asData?.value,
        ) ??
        ref.read(reflectControllerProvider).value?.today?.mood;
    final isToday =
        entry == null ||
        (entry.entryDate != null && _sameDate(entry.entryDate!, _today()));
    if (isToday && resolvedTodayMood == null) {
      _promptMoodBeforeWriting(context);
      return;
    }
    var selectedEntry = entry;
    if (entry != null) {
      try {
        selectedEntry =
            await ref
                .read(journalControllerProvider.notifier)
                .loadEntry(entry.id) ??
            entry;
      } catch (_) {
        if (context.mounted) _showFailure(context);
        return;
      }
      if (!context.mounted) return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => JournalEditorScreen(
              entry: selectedEntry,
              kind: JournalKind.daily,
            ),
      ),
    );
  }

  void _promptMoodBeforeWriting(BuildContext context) {
    final strings = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(strings.journalMoodRequired),
          action: SnackBarAction(
            label: strings.journalChooseMood,
            onPressed: () => context.go('/reflect'),
          ),
        ),
      );
  }

  Future<void> _editLetter(
    BuildContext context,
    WidgetRef ref, {
    JournalEntry? entry,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => JournalEditorScreen(
              entry: entry,
              kind: JournalKind.futureLetter,
            ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    JournalEntry entry,
  ) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(strings.journalDeleteTitle),
            content: Text(strings.journalDeleteBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.keep),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.delete),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    final deleted = await ref
        .read(journalControllerProvider.notifier)
        .delete(entry.id);
    if (deleted && entry.kind == JournalKind.futureLetter) {
      await ref.read(notificationServiceProvider).cancelFutureLetter(entry.id);
    }
    if (!context.mounted) return;
    _showResult(context, deleted, strings.journalDeleted);
  }

  void _showResult(BuildContext context, bool success, String successMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? successMessage : AppLocalizations.of(context).saveFailed,
        ),
      ),
    );
  }

  void _showFailure(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).futureLetterOpenFailed),
      ),
    );
  }
}

class _DailyCalendarSection extends StatelessWidget {
  const _DailyCalendarSection({
    required this.calendar,
    required this.hasTodayEntry,
    required this.todayMood,
    required this.onWriteToday,
    required this.onOpen,
  });

  final JournalCalendarData calendar;
  final bool hasTodayEntry;
  final Mood? todayMood;
  final VoidCallback onWriteToday;
  final ValueChanged<JournalEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuseSectionLabel(
          strings.dailyJournal,
          trailing: MusePill(
            label:
                todayMood == null
                    ? strings.journalChooseMoodFirst
                    : hasTodayEntry
                    ? strings.journalEditToday
                    : strings.journalWriteToday,
            icon:
                todayMood == null
                    ? Icons.mood_outlined
                    : hasTodayEntry
                    ? Icons.edit_outlined
                    : Icons.add_rounded,
            onTap: onWriteToday,
          ),
        ),
        const SizedBox(height: 10),
        for (final month in calendar.months)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _MonthCalendar(
              month: month,
              today: calendar.today,
              onOpen: onOpen,
            ),
          ),
        if (calendar.months.length == 1)
          Text(
            strings.journalPastHint,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.today,
    required this.onOpen,
  });

  final JournalCalendarMonth month;
  final DateTime today;
  final ValueChanged<JournalEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final firstDay = DateTime.utc(month.year, month.month, 1);
    final leading = firstDay.weekday - 1;
    final cells = <Widget>[
      for (var index = 0; index < leading; index++) const SizedBox.shrink(),
      for (final day in month.days)
        _CalendarDayCell(
          day: day,
          today: today,
          onOpen: day.journal == null ? null : () => onOpen(day.journal!),
        ),
    ];
    return MuseGlassCard(
      tint: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                material.formatMonthYear(DateTime(month.year, month.month)),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (month.year == today.year && month.month == today.month)
                MusePill(label: strings.journalViewing, selected: true),
              if (!(month.year == today.year && month.month == today.month))
                const Icon(
                  Icons.history_rounded,
                  size: 17,
                  color: MuseColors.mutedInk,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final index in const [1, 2, 3, 4, 5, 6, 0])
                _WeekdayLabel(material.narrowWeekdays[index]),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 7,
            crossAxisSpacing: 5,
            children: cells,
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: MuseColors.mutedInk,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({required this.day, required this.today, this.onOpen});

  final JournalCalendarDay day;
  final DateTime today;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isFuture = day.date.isAfter(today);
    if (isFuture) return const SizedBox.shrink();
    final mood = day.checkin?.mood;
    final isToday = day.date == today;
    final hasActivity = day.hasActivity;
    return Semantics(
      button: onOpen != null,
      label: strings.journalDaySemantics(
        day.date.day,
        day.date.month,
        mood == null
            ? ''
            : strings.journalMoodSemantics(
              mood.localizedLabel(strings).toLowerCase(),
            ),
        day.isWritten ? strings.journalWrittenSemantics : '',
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                mood != null
                    ? mood.visual.backgroundColor.withValues(alpha: .9)
                    : day.isWritten
                    ? MuseColors.teal.withValues(alpha: .18)
                    : Colors.transparent,
            border: Border.all(
              color:
                  isToday
                      ? MuseColors.teal
                      : hasActivity
                      ? Colors.white.withValues(alpha: .86)
                      : MuseColors.mutedInk.withValues(
                        alpha: isFuture ? .12 : .22,
                      ),
              width: isToday ? 2 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (mood != null && !isFuture)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Image.asset(
                    mood.visual.assetPath,
                    width: 29,
                    height: 25,
                    fit: BoxFit.contain,
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '${day.date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                      color: MuseColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalCalendarLoading extends StatelessWidget {
  const _JournalCalendarLoading({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return MuseGlassCard(
      padding: EdgeInsets.all(compact ? 20 : 30),
      child: Center(
        child:
            compact
                ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyFutureLetters extends StatelessWidget {
  const _EmptyFutureLetters({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return MuseGlassCard(
      tint: MuseColors.lavender,
      child: Column(
        children: [
          const Icon(
            Icons.mark_email_unread_outlined,
            size: 34,
            color: MuseColors.teal,
          ),
          const SizedBox(height: 8),
          Text(strings.futureLettersEmpty, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.edit_rounded),
            label: Text(strings.futureLetterWriteFirst),
          ),
        ],
      ),
    );
  }
}

class _JournalCard extends ConsumerWidget {
  const _JournalCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final isLetter = entry.kind == JournalKind.futureLetter;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MuseGlassCard(
        padding: EdgeInsets.zero,
        tint: isLetter ? MuseColors.lavender : MuseColors.sky,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          isThreeLine: entry.tags.isNotEmpty,
          leading:
              entry.media.isEmpty
                  ? CircleAvatar(
                    backgroundColor:
                        isLetter ? MuseColors.lavender : MuseColors.mint,
                    child: Icon(
                      isLetter ? Icons.mail_outline : Icons.auto_stories,
                    ),
                  )
                  : _PrivateImage(media: entry.media.first),
          title: Text(
            entry.title?.trim().isNotEmpty == true
                ? entry.title!
                : isLetter
                ? strings.futureLetters
                : strings.journalMyDay,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLetter
                    ? strings.futureLetterScheduleState(
                      _date(entry.deliverAt!),
                      entry.openedAt == null
                          ? strings.futureLetterUnopened
                          : strings.futureLetterOpened,
                    )
                    : '${_date(entry.entryDate!)} · ${_preview(strings, entry.content)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: [
                    for (final tag in entry.tags)
                      Text(
                        '#${tag.name}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
            ],
          ),
          trailing: PopupMenuButton<_JournalCardAction>(
            tooltip: strings.futureLetterOptions,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) {
              if (action == _JournalCardAction.delete) onDelete();
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: _JournalCardAction.delete,
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline),
                        const SizedBox(width: 10),
                        Text(strings.futureLetterDelete),
                      ],
                    ),
                  ),
                ],
          ),
        ),
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String _preview(AppLocalizations strings, String value) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return clean.isEmpty ? strings.journalNoContent : clean;
  }
}

enum _JournalCardAction { delete }

class _PrivateImage extends ConsumerWidget {
  const _PrivateImage({required this.media});

  final JournalMedia media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedUrl = ref.watch(journalMediaUrlProvider(media.storagePath));
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: 48,
        child: signedUrl.when(
          loading:
              () => const ColoredBox(
                color: MuseColors.mint,
                child: Icon(Icons.image_outlined),
              ),
          error:
              (_, _) => const ColoredBox(
                color: MuseColors.mint,
                child: Icon(Icons.broken_image_outlined),
              ),
          data:
              (url) => Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, _, _) => const ColoredBox(
                      color: MuseColors.mint,
                      child: Icon(Icons.broken_image_outlined),
                    ),
              ),
        ),
      ),
    );
  }
}

class _JournalError extends StatelessWidget {
  const _JournalError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MuseGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(AppLocalizations.of(context).journalLoadFailed),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}
