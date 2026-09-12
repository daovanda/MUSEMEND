import 'package:musemend/features/quotes/domain/daily_quote.dart';

class DailyQuoteDto {
  const DailyQuoteDto({
    required this.rotationOrder,
    required this.content,
    required this.topic,
    required this.quoteDate,
  });

  final int rotationOrder;
  final String content;
  final String topic;
  final DateTime quoteDate;

  factory DailyQuoteDto.fromMap(Map<String, dynamic> map) {
    return DailyQuoteDto(
      rotationOrder: (map['rotation_order'] as num).toInt(),
      content: map['content'] as String,
      topic: map['topic'] as String,
      quoteDate: DateTime.parse(map['quote_date'] as String),
    );
  }

  DailyQuote toDomain() => DailyQuote(
    rotationOrder: rotationOrder,
    content: content,
    topic: topic,
    quoteDate: quoteDate,
  );
}
