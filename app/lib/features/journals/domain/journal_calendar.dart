import 'package:musemend/features/checkin/domain/daily_checkin.dart';
import 'package:musemend/features/journals/domain/journal_entry.dart';

class JournalCalendarData {
  const JournalCalendarData({required this.months, required this.today});

  final List<JournalCalendarMonth> months;
  final DateTime today;
}

class JournalCalendarMonth {
  const JournalCalendarMonth({
    required this.year,
    required this.month,
    required this.days,
  });

  final int year;
  final int month;
  final List<JournalCalendarDay> days;
}

class JournalCalendarDay {
  const JournalCalendarDay({required this.date, this.checkin, this.journal});

  final DateTime date;
  final DailyCheckin? checkin;
  final JournalEntry? journal;

  bool get hasActivity => checkin != null || journal != null;
  bool get isWritten => journal != null;
}
