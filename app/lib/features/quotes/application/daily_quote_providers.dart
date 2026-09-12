import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/core/supabase/supabase_client_provider.dart';
import 'package:musemend/features/quotes/data/supabase_daily_quote_repository.dart';
import 'package:musemend/features/quotes/domain/daily_quote.dart';
import 'package:musemend/features/quotes/domain/daily_quote_repository.dart';
import 'package:musemend/core/localization/supported_locales.dart';
import 'package:musemend/features/profile/application/profile_providers.dart';

final dailyQuoteRepositoryProvider = Provider<DailyQuoteRepository>((ref) {
  return SupabaseDailyQuoteRepository(ref.watch(supabaseClientProvider));
});

final dailyQuoteProvider = FutureProvider.autoDispose<DailyQuote>((ref) async {
  final timer = Timer(_durationUntilNextVietnamDay(), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  final storedLanguage = ref.watch(appLanguageCodeProvider).value;
  final languageCode = resolveSupportedLanguageCode(
    storedLanguage ??
        resolveDeviceLocale(PlatformDispatcher.instance.locales).languageCode,
  );
  return ref
      .watch(dailyQuoteRepositoryProvider)
      .loadToday(languageCode: languageCode);
});

Duration _durationUntilNextVietnamDay() {
  final nowUtc = DateTime.now().toUtc();
  final vietnamNow = nowUtc.add(const Duration(hours: 7));
  final nextVietnamDay = DateTime.utc(
    vietnamNow.year,
    vietnamNow.month,
    vietnamNow.day + 1,
  );
  final nextMidnightUtc = nextVietnamDay.subtract(const Duration(hours: 7));
  return nextMidnightUtc.difference(nowUtc) + const Duration(seconds: 1);
}
