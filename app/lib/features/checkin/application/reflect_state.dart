import 'package:musemend/features/checkin/domain/daily_checkin.dart';

class ReflectState {
  const ReflectState({required this.streak, required this.today});

  final int streak;
  final DailyCheckin? today;

  ReflectState copyWith({int? streak, DailyCheckin? today}) {
    return ReflectState(
      streak: streak ?? this.streak,
      today: today ?? this.today,
    );
  }
}
