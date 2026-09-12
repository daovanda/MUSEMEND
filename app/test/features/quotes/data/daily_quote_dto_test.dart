import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/quotes/data/daily_quote_dto.dart';

void main() {
  test('maps the daily quote RPC response', () {
    final quote =
        DailyQuoteDto.fromMap({
          'rotation_order': 42,
          'content':
              'Một ngày khó khăn không phải là toàn bộ câu chuyện của bạn.',
          'topic': 'life',
          'quote_date': '2026-09-12',
        }).toDomain();

    expect(quote.rotationOrder, 42);
    expect(quote.topic, 'life');
    expect(quote.quoteDate, DateTime(2026, 9, 12));
    expect(quote.content, contains('toàn bộ câu chuyện'));
  });
}
