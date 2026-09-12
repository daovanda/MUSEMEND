import 'package:musemend/features/quotes/domain/daily_quote.dart';

abstract interface class DailyQuoteRepository {
  Future<DailyQuote> loadToday();
}
