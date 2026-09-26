import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/checkin/domain/sky_day.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

/// Twenty combinations per day phase. The index changes once per Vietnam day,
/// so a rebuild, navigation or language change never picks a different idea.
String morningMessage(AppLocalizations strings, DateTime instant) {
  final index = skyDayNumber(instant) % 20;
  final opening =
      [
        strings.skyMorningOpening1,
        strings.skyMorningOpening2,
        strings.skyMorningOpening3,
        strings.skyMorningOpening4,
      ][index ~/ 5];
  final ending =
      [
        strings.skyMorningEnding1,
        strings.skyMorningEnding2,
        strings.skyMorningEnding3,
        strings.skyMorningEnding4,
        strings.skyMorningEnding5,
      ][index % 5];
  return '$opening $ending';
}

String moodResponse(AppLocalizations strings, Mood mood, DateTime instant) {
  final index = (skyDayNumber(instant) + mood.score * 7) % 20;
  final openings = switch (mood) {
    Mood.awful => [strings.skyAwfulOpening1, strings.skyAwfulOpening2],
    Mood.sad => [strings.skySadOpening1, strings.skySadOpening2],
    Mood.okay => [strings.skyOkayOpening1, strings.skyOkayOpening2],
    Mood.good => [strings.skyGoodOpening1, strings.skyGoodOpening2],
    Mood.great => [strings.skyGreatOpening1, strings.skyGreatOpening2],
  };
  final endings = [
    strings.skyResponseEnding1,
    strings.skyResponseEnding2,
    strings.skyResponseEnding3,
    strings.skyResponseEnding4,
    strings.skyResponseEnding5,
    strings.skyResponseEnding6,
    strings.skyResponseEnding7,
    strings.skyResponseEnding8,
    strings.skyResponseEnding9,
    strings.skyResponseEnding10,
  ];
  return '${openings[index ~/ 10]} ${endings[index % 10]}';
}
