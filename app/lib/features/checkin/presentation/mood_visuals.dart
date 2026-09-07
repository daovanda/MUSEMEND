import 'package:flutter/material.dart';
import 'package:musemend/features/checkin/domain/mood.dart';

@immutable
class MoodVisualSpec {
  const MoodVisualSpec({
    required this.label,
    required this.assetPath,
    required this.backgroundColor,
    required this.left,
    required this.width,
    required this.height,
    required this.rotationDegrees,
    required this.imageSize,
  });

  final String label;
  final String assetPath;
  final Color backgroundColor;
  final double left;
  final double width;
  final double height;
  final double rotationDegrees;
  final double imageSize;
}

/// Visual tokens measured from Figma page Home, frame Bầu trời.
const moodVisualSpecs = <Mood, MoodVisualSpec>{
  Mood.awful: MoodVisualSpec(
    label: 'QUẠO',
    assetPath: 'assets/illustrations/clouds/moods/awful.png',
    backgroundColor: Color(0x33FFCDD2),
    left: -18,
    width: 47.09,
    height: 62.89,
    rotationDegrees: 8,
    imageSize: 30,
  ),
  Mood.sad: MoodVisualSpec(
    label: 'TRỐNG RỖNG',
    assetPath: 'assets/illustrations/clouds/moods/sad.png',
    backgroundColor: Color(0x339CB4D8),
    left: 40,
    width: 55,
    height: 73.45,
    rotationDegrees: 4,
    imageSize: 36,
  ),
  Mood.okay: MoodVisualSpec(
    label: 'ỔN ÁP',
    assetPath: 'assets/illustrations/clouds/moods/okay.png',
    backgroundColor: Color(0x33FFFFFF),
    left: 102,
    width: 70,
    height: 93,
    rotationDegrees: 0,
    imageSize: 54,
  ),
  Mood.good: MoodVisualSpec(
    label: 'THƯ GIÃN',
    assetPath: 'assets/illustrations/clouds/moods/good.png',
    backgroundColor: Color(0x33FFF9C4),
    left: 174,
    width: 55,
    height: 73.45,
    rotationDegrees: -4,
    imageSize: 36,
  ),
  Mood.great: MoodVisualSpec(
    label: 'CHỮA LÀNH',
    assetPath: 'assets/illustrations/clouds/moods/great.png',
    backgroundColor: Color(0x33DCEDC8),
    left: 236,
    width: 47.09,
    height: 62.89,
    rotationDegrees: -8,
    imageSize: 30,
  ),
};

extension MoodVisuals on Mood {
  MoodVisualSpec get visual => moodVisualSpecs[this]!;
}
