import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/features/journals/application/journal_providers.dart';
import 'package:musemend/features/journals/domain/journal_entry.dart';
import 'package:musemend/features/journals/domain/journal_media.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalControllerProvider);
    return ColoredBox(
      color: MuseColors.cream,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: ref.read(journalControllerProvider.notifier).reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            children: [
              Text('Nhật ký', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 6),
              const Text('Một nơi riêng tư để giữ lại điều bạn muốn nhớ.'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _editDaily(context, ref),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Viết hôm nay'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editLetter(context, ref),
                      icon: const Icon(Icons.forward_to_inbox_outlined),
                      label: const Text('Thư tương lai'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              entries.when(
                loading:
                    () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (_, _) => _JournalError(
                      onRetry:
                          ref.read(journalControllerProvider.notifier).reload,
                    ),
                data:
                    (items) =>
                        items.isEmpty
                            ? const _EmptyJournal()
                            : Column(
                              children: items
                                  .map(
                                    (entry) => _JournalCard(
                                      entry: entry,
                                      onTap:
                                          () => _openEntry(context, ref, entry),
                                      onAttach:
                                          () =>
                                              _attachImage(context, ref, entry),
                                      onDelete:
                                          () => _delete(context, ref, entry),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEntry(
    BuildContext context,
    WidgetRef ref,
    JournalEntry entry,
  ) async {
    if (entry.kind == JournalKind.daily) {
      await _editDaily(context, ref, entry: entry);
      return;
    }
    if (entry.openedAt == null) {
      final opened = await ref
          .read(journalControllerProvider.notifier)
          .open(entry.id);
      if (!context.mounted || !opened) {
        if (context.mounted) _showFailure(context);
        return;
      }
    }
    if (context.mounted) await _editLetter(context, ref, entry: entry);
  }

  Future<void> _editDaily(
    BuildContext context,
    WidgetRef ref, {
    JournalEntry? entry,
  }) async {
    final draft = await showDialog<_JournalDraft>(
      context: context,
      builder:
          (_) => _JournalEditorDialog(
            title: entry?.title ?? '',
            content: entry?.content ?? '',
            heading: entry == null ? 'Viết cho hôm nay' : 'Sửa nhật ký',
          ),
    );
    if (draft == null) return;
    final saved = await ref
        .read(journalControllerProvider.notifier)
        .saveDaily(id: entry?.id, title: draft.title, content: draft.content);
    if (!context.mounted) return;
    _showResult(context, saved, 'Nhật ký đã được lưu.');
  }

  Future<void> _editLetter(
    BuildContext context,
    WidgetRef ref, {
    JournalEntry? entry,
  }) async {
    final draft = await showDialog<_LetterDraft>(
      context: context,
      builder: (_) => _LetterEditorDialog(entry: entry),
    );
    if (draft == null) return;
    final saved = await ref
        .read(journalControllerProvider.notifier)
        .saveFutureLetter(
          id: entry?.id,
          title: draft.title,
          content: draft.content,
          deliverAt: draft.deliverAt,
        );
    if (!context.mounted) return;
    _showResult(context, saved, 'Thư tương lai đã được lưu.');
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    JournalEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Xóa mục này?'),
            content: const Text(
              'Mục sẽ được ẩn ngay. Tệp liên quan được dọn theo chính sách xóa mềm.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Giữ lại'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    final deleted = await ref
        .read(journalControllerProvider.notifier)
        .delete(entry.id);
    if (!context.mounted) return;
    _showResult(context, deleted, 'Đã xóa mục nhật ký.');
  }

  Future<void> _attachImage(
    BuildContext context,
    WidgetRef ref,
    JournalEntry entry,
  ) async {
    final result = await ref
        .read(journalControllerProvider.notifier)
        .attachImage(entry.id);
    if (!context.mounted || result == JournalImageResult.canceled) return;
    final message = switch (result) {
      JournalImageResult.success => 'Ảnh đã được lưu riêng tư.',
      JournalImageResult.tooLarge => 'Ảnh vượt quá giới hạn 10 MiB.',
      JournalImageResult.unsupported => 'Chỉ hỗ trợ JPG, PNG, WebP hoặc HEIC.',
      JournalImageResult.failed => 'Chưa thể tải ảnh lên. Hãy thử lại.',
      JournalImageResult.canceled => '',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showResult(BuildContext context, bool success, String successMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? successMessage : 'Chưa thể lưu. Hãy thử lại.'),
      ),
    );
  }

  void _showFailure(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chưa thể mở thư. Hãy thử lại.')),
    );
  }
}

class _JournalCard extends ConsumerWidget {
  const _JournalCard({
    required this.entry,
    required this.onTap,
    required this.onAttach,
    required this.onDelete,
  });

  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback onAttach;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLetter = entry.kind == JournalKind.futureLetter;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        leading:
            entry.media.isEmpty
                ? CircleAvatar(
                  backgroundColor:
                      isLetter ? MuseColors.lavender : MuseColors.mint,
                  child: Icon(
                    isLetter ? Icons.mail_outline : Icons.auto_stories,
                  ),
                )
                : _PrivateImage(media: entry.media.first),
        title: Text(
          entry.title?.trim().isNotEmpty == true
              ? entry.title!
              : isLetter
              ? 'Thư gửi tương lai'
              : 'Một ngày của tôi',
        ),
        subtitle: Text(
          isLetter
              ? 'Hẹn ${_date(entry.deliverAt!)} · ${entry.openedAt == null ? 'chưa mở' : 'đã mở'}'
              : '${_date(entry.entryDate!)} · ${_preview(entry.content)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Thêm ảnh riêng tư',
              onPressed: onAttach,
              icon: Badge(
                isLabelVisible: entry.media.isNotEmpty,
                label: Text('${entry.media.length}'),
                child: const Icon(Icons.add_photo_alternate_outlined),
              ),
            ),
            IconButton(
              tooltip: 'Xóa',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String _preview(String value) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return clean.isEmpty ? 'Chưa có nội dung' : clean;
  }
}

class _PrivateImage extends ConsumerWidget {
  const _PrivateImage({required this.media});

  final JournalMedia media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedUrl = ref.watch(journalMediaUrlProvider(media.storagePath));
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: 48,
        child: signedUrl.when(
          loading:
              () => const ColoredBox(
                color: MuseColors.mint,
                child: Icon(Icons.image_outlined),
              ),
          error:
              (_, _) => const ColoredBox(
                color: MuseColors.mint,
                child: Icon(Icons.broken_image_outlined),
              ),
          data:
              (url) => Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, _, _) => const ColoredBox(
                      color: MuseColors.mint,
                      child: Icon(Icons.broken_image_outlined),
                    ),
              ),
        ),
      ),
    );
  }
}

class _JournalEditorDialog extends StatefulWidget {
  const _JournalEditorDialog({
    required this.title,
    required this.content,
    required this.heading,
  });

  final String title;
  final String content;
  final String heading;

  @override
  State<_JournalEditorDialog> createState() => _JournalEditorDialogState();
}

class _JournalEditorDialogState extends State<_JournalEditorDialog> {
  late final _title = TextEditingController(text: widget.title);
  late final _content = TextEditingController(text: widget.content);

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.heading),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Tiêu đề'),
            ),
            TextField(
              controller: _content,
              onChanged: (_) => setState(() {}),
              minLines: 5,
              maxLines: 10,
              maxLength: 10000,
              decoration: const InputDecoration(labelText: 'Nội dung'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed:
              _content.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(
                    context,
                    _JournalDraft(_title.text, _content.text),
                  ),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

class _LetterEditorDialog extends StatefulWidget {
  const _LetterEditorDialog({required this.entry});

  final JournalEntry? entry;

  @override
  State<_LetterEditorDialog> createState() => _LetterEditorDialogState();
}

class _LetterEditorDialogState extends State<_LetterEditorDialog> {
  late final _title = TextEditingController(text: widget.entry?.title ?? '');
  late final _content = TextEditingController(
    text: widget.entry?.content ?? '',
  );
  late DateTime _delivery =
      widget.entry?.deliverAt?.toLocal() ??
      DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entry == null ? 'Thư gửi tương lai' : 'Sửa lá thư'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Tiêu đề'),
            ),
            TextField(
              controller: _content,
              onChanged: (_) => setState(() {}),
              minLines: 5,
              maxLines: 10,
              maxLength: 10000,
              decoration: const InputDecoration(labelText: 'Lời nhắn'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ngày nhắc mở thư'),
              subtitle: Text(_JournalCard._date(_delivery)),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed:
              _content.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(
                    context,
                    _LetterDraft(_title.text, _content.text, _delivery),
                  ),
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate:
          _delivery.isAfter(now) ? _delivery : now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day + 1),
      lastDate: DateTime(now.year + 10),
    );
    if (selected != null) {
      setState(
        () =>
            _delivery = DateTime(
              selected.year,
              selected.month,
              selected.day,
              9,
            ),
      );
    }
  }
}

class _JournalDraft {
  const _JournalDraft(this.title, this.content);

  final String title;
  final String content;
}

class _LetterDraft extends _JournalDraft {
  const _LetterDraft(super.title, super.content, this.deliverAt);

  final DateTime deliverAt;
}

class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Chưa có trang nào. Bạn có thể bắt đầu bằng vài dòng thật ngắn.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _JournalError extends StatelessWidget {
  const _JournalError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Chưa thể tải nhật ký lúc này.'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
