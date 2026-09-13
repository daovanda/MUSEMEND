enum Mood {
  great('great', 5),
  good('good', 4),
  okay('okay', 3),
  sad('sad', 2),
  awful('awful', 1);

  const Mood(this.databaseValue, this.score);

  final String databaseValue;
  final int score;

  static Mood fromDatabase(String value) {
    return Mood.values.firstWhere(
      (mood) => mood.databaseValue == value,
      orElse: () => throw FormatException('Unsupported mood value: $value'),
    );
  }
}
