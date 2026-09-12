class DailyQuote {
  const DailyQuote({
    required this.rotationOrder,
    required this.content,
    required this.topic,
    required this.quoteDate,
  });

  final int rotationOrder;
  final String content;
  final String topic;
  final DateTime quoteDate;
}
