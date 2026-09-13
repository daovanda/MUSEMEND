import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/core/localization/supported_locales.dart';

void main() {
  test('every supported locale explicitly translates every Vietnamese key', () {
    final files =
        Directory('lib/l10n')
            .listSync()
            .whereType<File>()
            .where((file) => RegExp(r'app_[a-z]{2}\.arb$').hasMatch(file.path))
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));
    final reference = _messages(File('lib/l10n/app_vi.arb'));

    expect(
      files.map((file) => _languageCode(file)).toSet(),
      supportedLanguageCodes,
    );
    for (final file in files) {
      final messages = _messages(file);
      expect(
        messages.keys.toSet(),
        reference.keys.toSet(),
        reason: '${file.path} must not rely on generated English fallback.',
      );
      for (final key in reference.keys) {
        expect(
          messages[key]?.trim(),
          isNotEmpty,
          reason: '${file.path} has an empty translation for "$key".',
        );
        expect(
          _placeholders(messages[key]!),
          _placeholders(reference[key]!),
          reason: '${file.path} changes the placeholders for "$key".',
        );
      }
    }
  });
}

String _languageCode(File file) =>
    RegExp(r'app_([a-z]{2})\.arb$').firstMatch(file.path)!.group(1)!;

Set<String> _placeholders(String message) => RegExp(
  r'\{[a-zA-Z][a-zA-Z0-9_]*\}',
).allMatches(message).map((match) => match.group(0)!).toSet();

Map<String, String> _messages(File file) {
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final entry in decoded.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
  };
}
