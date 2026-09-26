import 'package:flutter_riverpod/flutter_riverpod.dart';

final skyNowProvider = NotifierProvider<SkyClockController, DateTime>(
  SkyClockController.new,
);

class SkyClockController extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void update(DateTime now) => state = now;
}
