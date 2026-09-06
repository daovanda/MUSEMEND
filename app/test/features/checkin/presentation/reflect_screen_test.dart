import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/checkin/application/reflect_providers.dart';
import 'package:musemend/features/checkin/domain/app_visit.dart';
import 'package:musemend/features/checkin/domain/checkin_repository.dart';
import 'package:musemend/features/checkin/domain/daily_checkin.dart';
import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/checkin/presentation/reflect_screen.dart';

void main() {
  testWidgets('shows a retry state when initial network requests fail', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkinRepositoryProvider.overrideWithValue(
            _OfflineCheckinRepository(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ReflectScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa thể tải dữ liệu của bạn.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}

class _OfflineCheckinRepository implements CheckinRepository {
  @override
  Future<DailyCheckin?> loadToday() =>
      Future.error(TimeoutException('offline'));

  @override
  Future<AppVisit> recordAppOpen() => Future.error(TimeoutException('offline'));

  @override
  Future<DailyCheckin> saveToday({
    required Mood mood,
    required int? energyLevel,
    required String? note,
  }) => Future.error(TimeoutException('offline'));
}
