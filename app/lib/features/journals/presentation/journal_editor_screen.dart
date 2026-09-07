import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/features/journals/application/journal_providers.dart';
import 'package:musemend/features/journals/domain/journal_entry.dart';
import 'package:musemend/features/journals/domain/journal_media.dart';
import 'package:musemend/features/notifications/application/notification_providers.dart';
import 'package:musemend/features/notifications/domain/future_letter_reminder.dart';
import 'package:musemend/features/profile/application/profile_providers.dart';

/// Full-page writing experience. Unlike mission/settings forms, writing is not
/// constrained to a dialog: the keyboard, text and private attachments get
/// the whole viewport and can be revisited without losing context.
class JournalEditorScreen extends ConsumerStatefulWidget {
  const JournalEditorScreen({this.entry, required this.kind, super.key});

  final JournalEntry? entry;
  final JournalKind kind;

  @override
  ConsumerState<JournalEditorScreen> createState() =>
      _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final TextEditingController _tags;
  late DateTime _delivery;
  late bool _notifyOnDevice;
  late List<JournalMedia> _media;
  var _saving = false;
  String? _savedId;

  bool get _isLetter => widget.kind == JournalKind.futureLetter;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _title = TextEditingController(text: entry?.title ?? '');
    _content = TextEditingController(text: entry?.content ?? '');
    _tags = TextEditingController(
      text: entry?.tags.map((tag) => tag.name).join(', ') ?? '',
    );
    _delivery =
        entry?.deliverAt?.toLocal() ??
        DateTime.now().add(const Duration(days: 1));
    _notifyOnDevice =
        ref.read(accountOverviewProvider).value?.settings.notificationEnabled ??
        false;
    _savedId = entry?.id;
    _media = List.unmodifiable(entry?.media ?? const <JournalMedia>[]);
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existingMedia = _media;
    final letterTitleStyle = TextStyle(
      fontFamily: 'serif',
      fontSize: 28,
      height: 1.2,
      color: MuseColors.ink,
      fontWeight: FontWeight.w700,
    );
    final letterBodyStyle = TextStyle(
      fontFamily: 'serif',
      fontSize: 18,
      height: 1.75,
      color: MuseColors.ink,
    );
    final letterHintStyle = TextStyle(
      fontFamily: 'serif',
      fontSize: 18,
      height: 1.75,
      color: MuseColors.mutedInk.withValues(alpha: .62),
      fontStyle: FontStyle.italic,
    );
    final inputDecoration = InputDecoration(
      filled: false,
      fillColor: Colors.transparent,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      counterText: '',
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MusePageBackground(
        accent: _isLetter ? MuseColors.lavender : MuseColors.sky,
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                title:
                    _isLetter
                        ? (widget.entry == null
                            ? 'Thư gửi tương lai'
                            : 'Sửa lá thư')
                        : (widget.entry == null
                            ? 'Viết cho hôm nay'
                            : 'Sửa nhật ký'),
                onBack: () => Navigator.of(context).maybePop(),
                onSave: _saving ? null : _save,
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(26, 14, 26, 40),
                  children: [
                    if (!_isLetter)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _letterDateLabel,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 15,
                            height: 1.35,
                            color: MuseColors.teal,
                            fontStyle: FontStyle.italic,
                            letterSpacing: .4,
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _title,
                      maxLength: 120,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: inputDecoration.copyWith(
                        hintText:
                            _isLetter ? 'Một lời nhắn cho mai sau' : 'Tiêu đề',
                        hintStyle: letterTitleStyle.copyWith(
                          color: MuseColors.mutedInk.withValues(alpha: .55),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      style: letterTitleStyle,
                    ),
                    const SizedBox(height: 9),
                    Divider(color: MuseColors.teal.withValues(alpha: .22)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _content,
                      maxLength: 10000,
                      minLines: 14,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: inputDecoration.copyWith(
                        hintText: 'Hôm nay bạn muốn kể điều gì với chính mình?',
                        hintStyle: letterHintStyle,
                      ),
                      style: letterBodyStyle,
                    ),
                    const SizedBox(height: 22),
                    _AttachmentTray(
                      media: existingMedia,
                      enabled: _savedId != null && !_saving,
                      onAdd: _attachImage,
                      onChanged: _updateMediaTransform,
                      onCommit: _persistMediaTransform,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text(
                          'Gắn nhãn',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 15,
                            color: MuseColors.teal,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_tags.text.trim().isEmpty ? 0 : _tagNames(_tags.text).length}/8',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _tags,
                      onChanged: (_) => setState(() {}),
                      maxLength: 320,
                      decoration: inputDecoration.copyWith(
                        hintText: 'gia đình, học tập, biết ơn',
                        hintStyle: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 15,
                          color: MuseColors.mutedInk.withValues(alpha: .6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 15,
                        color: MuseColors.ink,
                      ),
                    ),
                    if (_isLetter) ...[
                      const SizedBox(height: 22),
                      Divider(color: MuseColors.teal.withValues(alpha: .18)),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _notifyOnDevice,
                        onChanged:
                            ref
                                        .watch(accountOverviewProvider)
                                        .value
                                        ?.settings
                                        .notificationEnabled ==
                                    true
                                ? (value) =>
                                    setState(() => _notifyOnDevice = value)
                                : null,
                        title: const Text('Nhắc tôi trên thiết bị'),
                        subtitle: Text(
                          ref
                                      .watch(accountOverviewProvider)
                                      .value
                                      ?.settings
                                      .notificationEnabled ==
                                  true
                              ? 'Thông báo chỉ chứa lời nhắc chung, không hiển thị nội dung riêng tư.'
                              : 'Bật thông báo trong Cá nhân trước khi dùng.',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Divider(color: MuseColors.teal.withValues(alpha: .18)),
                      InkWell(
                        onTap: _pickDate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Ngày thư đến',
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      fontStyle: FontStyle.italic,
                                      color: MuseColors.teal,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _date(_delivery),
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: MuseColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Bạn vẫn có thể mở thư trước ngày này',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.calendar_month_outlined,
                                color: MuseColors.teal,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_saving) ...[
                      const SizedBox(height: 14),
                      const LinearProgressIndicator(minHeight: 3),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_content.text.trim().isEmpty || !_validTags(_tags.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy viết vài dòng và kiểm tra lại tag.')),
      );
      return;
    }
    setState(() => _saving = true);
    final controller = ref.read(journalControllerProvider.notifier);
    final id =
        _isLetter
            ? await controller.saveFutureLetter(
              id: _savedId,
              title: _title.text.trim(),
              content: _content.text,
              deliverAt: _delivery,
              tags: _tagNames(_tags.text),
            )
            : await controller.saveDaily(
              id: _savedId,
              title: _title.text.trim(),
              content: _content.text,
              tags: _tagNames(_tags.text),
            );
    if (!mounted) return;
    if (id == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa thể lưu. Hãy thử lại.')),
      );
      return;
    }
    _savedId = id;
    if (_isLetter) await _syncReminder(id);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  Future<void> _syncReminder(String id) async {
    try {
      final service = ref.read(notificationServiceProvider);
      if (!_notifyOnDevice) {
        await service.cancelFutureLetter(id);
        return;
      }
      if (await service.requestPermission()) {
        await service.scheduleFutureLetter(
          FutureLetterReminder(journalId: id, deliverAt: _delivery),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã lưu thư, nhưng chưa bật được nhắc trên thiết bị.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _attachImage() async {
    final id = _savedId;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy lưu trang trước, rồi thêm ảnh vào phần ghi chú.'),
        ),
      );
      return;
    }
    final result = await ref
        .read(journalControllerProvider.notifier)
        .attachImage(id);
    if (!mounted || result == JournalImageResult.canceled) return;
    if (result == JournalImageResult.success) {
      final updated = await ref
          .read(journalControllerProvider.notifier)
          .loadEntry(id);
      if (!mounted) return;
      if (updated != null) {
        setState(() => _media = List.unmodifiable(updated.media));
      }
    }
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

  void _updateMediaTransform(JournalMedia media) {
    setState(() {
      _media = List.unmodifiable([
        for (final item in _media) item.id == media.id ? media : item,
      ]);
    });
  }

  Future<void> _persistMediaTransform(JournalMedia media) async {
    try {
      await ref
          .read(journalControllerProvider.notifier)
          .updateMediaTransform(media);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa thể lưu vị trí ảnh. Hãy thử thao tác lại.'),
        ),
      );
    }
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

  String get _letterDateLabel {
    final value =
        _isLetter
            ? widget.entry?.updatedAt.toLocal() ?? DateTime.now()
            : widget.entry?.entryDate?.toLocal() ?? _vietnamToday();
    return 'Ngày ${value.day.toString().padLeft(2, '0')} '
        'tháng ${value.month.toString().padLeft(2, '0')} '
        'năm ${value.year}';
  }

  DateTime _vietnamToday() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return DateTime(now.year, now.month, now.day);
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onSave,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 14, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Quay lại',
          ),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          TextButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTray extends StatelessWidget {
  const _AttachmentTray({
    required this.media,
    required this.enabled,
    required this.onAdd,
    required this.onChanged,
    required this.onCommit,
  });

  final List<JournalMedia> media;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<JournalMedia> onChanged;
  final Future<void> Function(JournalMedia) onCommit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (media.isNotEmpty) ...[
          _EditableMediaCanvas(
            media: media,
            enabled: enabled,
            onChanged: onChanged,
            onCommit: onCommit,
          ),
          const SizedBox(height: 8),
          Text(
            'Kéo bằng một ngón tay · chụm để đổi cỡ · xoay bằng hai ngón tay',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MuseColors.mutedInk,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            const Icon(Icons.image_outlined, size: 18, color: MuseColors.teal),
            const SizedBox(width: 7),
            Text(
              media.isEmpty ? 'Đính kèm ảnh' : 'Ảnh trong trang viết',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: enabled ? onAdd : null,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Thêm ảnh'),
            ),
          ],
        ),
        if (media.isEmpty)
          Text(
            'Bạn có thể lưu trước rồi thêm ảnh vào bất kỳ lúc nào.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _EditableMediaCanvas extends StatelessWidget {
  const _EditableMediaCanvas({
    required this.media,
    required this.enabled,
    required this.onChanged,
    required this.onCommit,
  });

  final List<JournalMedia> media;
  final bool enabled;
  final ValueChanged<JournalMedia> onChanged;
  final Future<void> Function(JournalMedia) onCommit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 310.0;
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: _CanvasHint()),
              for (final item in media)
                _TransformableMedia(
                  media: item,
                  canvasSize: Size(width, height),
                  enabled: enabled,
                  onChanged: onChanged,
                  onCommit: onCommit,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CanvasHint extends StatelessWidget {
  const _CanvasHint();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Text(
          'Ảnh tự do trên trang viết',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 15,
            color: MuseColors.mutedInk.withValues(alpha: .32),
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _TransformableMedia extends ConsumerStatefulWidget {
  const _TransformableMedia({
    required this.media,
    required this.canvasSize,
    required this.enabled,
    required this.onChanged,
    required this.onCommit,
  });

  final JournalMedia media;
  final Size canvasSize;
  final bool enabled;
  final ValueChanged<JournalMedia> onChanged;
  final Future<void> Function(JournalMedia) onCommit;

  @override
  ConsumerState<_TransformableMedia> createState() =>
      _TransformableMediaState();
}

class _TransformableMediaState extends ConsumerState<_TransformableMedia> {
  JournalMedia? _startMedia;
  late JournalMedia _currentMedia = widget.media;
  Offset _startFocalPoint = Offset.zero;

  @override
  void didUpdateWidget(covariant _TransformableMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.id != widget.media.id || _startMedia == null) {
      _currentMedia = widget.media;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = _currentMedia;
    final width = widget.canvasSize.width * .64 * media.scale;
    final height = widget.canvasSize.height * .48 * media.scale;
    final left =
        widget.canvasSize.width / 2 +
        media.offsetX * widget.canvasSize.width -
        width / 2;
    final top =
        widget.canvasSize.height / 2 +
        media.offsetY * widget.canvasSize.height -
        height / 2;
    final signedUrl = ref.watch(journalMediaUrlProvider(media.storagePath));

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: media.rotation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: widget.enabled ? _onScaleStart : null,
                onScaleUpdate: widget.enabled ? _onScaleUpdate : null,
                onScaleEnd: widget.enabled ? (_) => _onScaleEnd() : null,
                child: signedUrl.when(
                  loading: () => const _MediaPlaceholder(),
                  error:
                      (_, _) => const _MediaPlaceholder(
                        icon: Icons.broken_image_outlined,
                      ),
                  data:
                      (url) => Image.network(
                        url,
                        fit: BoxFit.contain,
                        alignment: Alignment.topLeft,
                        errorBuilder:
                            (_, _, _) => const _MediaPlaceholder(
                              icon: Icons.broken_image_outlined,
                            ),
                      ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: IgnorePointer(
                child: Transform.scale(
                  scale: media.scale,
                  alignment: Alignment.topLeft,
                  child: const _MediaPin(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startMedia = _currentMedia;
    _startFocalPoint = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final start = _startMedia;
    if (start == null) return;
    final next = start.copyWith(
      offsetX: _clamp(
        start.offsetX +
            (details.focalPoint.dx - _startFocalPoint.dx) /
                widget.canvasSize.width,
        -2,
        2,
      ),
      offsetY: _clamp(
        start.offsetY +
            (details.focalPoint.dy - _startFocalPoint.dy) /
                widget.canvasSize.height,
        -2,
        2,
      ),
      scale: _clamp(start.scale * details.scale, .1, 5),
      rotation: start.rotation + details.rotation,
    );
    setState(() => _currentMedia = next);
    widget.onChanged(next);
  }

  void _onScaleEnd() {
    final current = _currentMedia;
    _startMedia = null;
    widget.onCommit(current);
  }

  double _clamp(double value, double min, double max) =>
      value.clamp(min, max).toDouble();
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({this.icon = Icons.image_outlined});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MuseColors.mint.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: MuseColors.teal),
    );
  }
}

class _MediaPin extends StatelessWidget {
  const _MediaPin();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -.18,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE24F55),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .22),
              blurRadius: 5,
              offset: const Offset(1, 3),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(5),
          child: Icon(Icons.push_pin, size: 22, color: Color(0xFFFFE8E5)),
        ),
      ),
    );
  }
}

List<String> _tagNames(String value) {
  final names = <String>[];
  final normalized = <String>{};
  for (final raw in value.split(',')) {
    final name = raw.trim();
    if (name.isEmpty || !normalized.add(name.toLowerCase())) continue;
    names.add(name);
  }
  return names;
}

bool _validTags(String value) {
  final names = _tagNames(value);
  return names.length <= 8 && names.every((name) => name.length <= 40);
}
