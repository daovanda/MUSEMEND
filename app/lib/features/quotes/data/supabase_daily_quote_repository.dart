import 'package:musemend/features/quotes/data/daily_quote_dto.dart';
import 'package:musemend/features/quotes/domain/daily_quote.dart';
import 'package:musemend/features/quotes/domain/daily_quote_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDailyQuoteRepository implements DailyQuoteRepository {
  SupabaseDailyQuoteRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<DailyQuote> loadToday({required String languageCode}) async {
    final result = await _client.rpc(
      'get_daily_quote',
      params: {'p_language_code': languageCode},
    );
    final row = _singleObject(result);
    return DailyQuoteDto.fromMap(row).toDomain();
  }

  Map<String, dynamic> _singleObject(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.length == 1 && value.single is Map) {
      return Map<String, dynamic>.from(value.single as Map);
    }
    throw const FormatException(
      'get_daily_quote returned an unexpected response.',
    );
  }
}
