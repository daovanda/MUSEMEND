enum Mood {
  great('great', 5, 'Rất tuyệt', '🌈'),
  good('good', 4, 'Ổn áp', '🌤️'),
  okay('okay', 3, 'Bình thường', '☁️'),
  sad('sad', 2, 'Hơi buồn', '🌧️'),
  awful('awful', 1, 'Rất tệ', '⛈️');

  const Mood(this.databaseValue, this.score, this.label, this.symbol);

  final String databaseValue;
  final int score;
  final String label;
  final String symbol;

  static Mood fromDatabase(String value) {
    return Mood.values.firstWhere(
      (mood) => mood.databaseValue == value,
      orElse: () => throw FormatException('Unsupported mood value: $value'),
    );
  }
}
