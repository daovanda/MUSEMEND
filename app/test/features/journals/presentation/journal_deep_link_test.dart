import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/journals/application/journal_providers.dart';
import 'package:musemend/features/journals/domain/journal_entry.dart';
import 'package:musemend/features/journals/domain/journal_media.dart';
import 'package:musemend/features/journals/domain/journal_repository.dart';
import 'package:musemend/features/journals/presentation/journal_screen.dart';

void main() {
  testWidgets('opens the journal entry selected by a deep link', (
    tester,
  ) async {
    const targetId = '00000000-0000-4000-8000-000000000001';
    final target = JournalEntry(
      id: targetId,
      kind: JournalKind.daily,
      title: 'Mục được nhắc',
      content: 'Nội dung riêng của mục đích.',
      updatedAt: DateTime.utc(2026, 9, 6),
      entryDate: DateTime.utc(2026, 9, 6),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            _FakeJournalRepository(target),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: JournalScreen(requestedEntryId: targetId)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sửa nhật ký'), findsOneWidget);
    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.text('Mục được nhắc')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: dialog,
        matching: find.text('Nội dung riêng của mục đích.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('does not expose an unavailable deep-link target', (
    tester,
  ) async {
    const visibleId = '00000000-0000-4000-8000-000000000001';
    const unavailableId = '00000000-0000-4000-8000-000000000002';
    final visibleEntry = JournalEntry(
      id: visibleId,
      kind: JournalKind.daily,
      title: 'Mục thuộc phiên hiện tại',
      content: 'Nội dung riêng tư',
      updatedAt: DateTime.utc(2026, 9, 6),
      entryDate: DateTime.utc(2026, 9, 6),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            _FakeJournalRepository(visibleEntry),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: JournalScreen(requestedEntryId: unavailableId)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy mục nhật ký này.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}

class _FakeJournalRepository implements JournalRepository {
  const _FakeJournalRepository(this.entry);

  final JournalEntry entry;

  @override
  Future<List<JournalEntry>> loadEntries() async => [entry];

  @override
  Future<JournalEntry?> loadEntry(String id) async =>
      id == entry.id ? entry : null;

  @override
  Future<void> attachImage(String journalId, PickedJournalImage image) async {}

  @override
  Future<String> createMediaUrl(String storagePath) async => storagePath;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> openFutureLetter(String id) async {}

  @override
  Future<String> saveDaily({
    String? id,
    required String title,
    required String content,
    required List<String> tags,
  }) async => id ?? entry.id;

  @override
  Future<String> saveFutureLetter({
    String? id,
    required String title,
    required String content,
    required DateTime deliverAt,
    required List<String> tags,
  }) async => id ?? entry.id;
}
