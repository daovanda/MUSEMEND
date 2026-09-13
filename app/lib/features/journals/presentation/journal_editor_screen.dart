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
import 'package:musemend/l10n/generated/app_localizations.dart';

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
    final strings = AppLocalizations.of(context);
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
                            ? strings.futureLetterCreateTitle
                            : strings.futureLetterEditTitle)
                        : (widget.entry == null
                            ? strings.journalWriteTitle
                            : strings.journalEditTitle),
                onBack: () => Navigator.of(context).maybePop(),
                onSave: _saving ? null : _save,
              ),
              Expanded(
                child: MuseResponsiveList(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  top: 14,
                  children: [
                    if (!_isLetter)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _entryDateLabel,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 15,
                            height: 1.35,
                            color: MuseColors.teal,
                            fontStyle: FontStyle.italic,
                            letterSpacing: .4,
                          ),
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _writingDateLabel,
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
                            _isLetter
                                ? strings.futureLetterTitleHint
                                : strings.journalTitleHint,
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
                        hintText: strings.journalContentHint,
                        hintStyle: letterHintStyle,
                      ),
                      style: letterBodyStyle,
                    ),
                    const SizedBox(height: 22),
                    _AttachmentTray(
                      media: existingMedia,
                      enabled: _savedId != null && !_saving,
                      onAdd: _attachImage,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text(
                          strings.journalTags,
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
                        hintText: strings.journalTagsHint,
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
                        title: Text(strings.futureLetterDeviceReminder),
                        subtitle: Text(
                          ref
                                      .watch(accountOverviewProvider)
                                      .value
                                      ?.settings
                                      .notificationEnabled ==
                                  true
                              ? strings.futureLetterReminderPrivate
                              : strings.futureLetterReminderDisabled,
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
                                    strings.futureLetterDeliveryDate,
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
                                    strings.futureLetterCanOpenEarly,
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
    final strings = AppLocalizations.of(context);
    if (_content.text.trim().isEmpty || !_validTags(_tags.text)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.journalContentValidation)));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.saveFailed)));
      return;
    }
    _savedId = id;
    if (_isLetter) await _syncReminder(id);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  Future<void> _syncReminder(String id) async {
    final strings = AppLocalizations.of(context);
    final reminder = FutureLetterReminder(
      journalId: id,
      deliverAt: _delivery,
      title: strings.futureLetterNotificationTitle,
      body: strings.futureLetterNotificationBody,
      channelName: strings.futureLetterNotificationChannel,
      channelDescription: strings.futureLetterNotificationChannelDescription,
    );
    try {
      final service = ref.read(notificationServiceProvider);
      if (!_notifyOnDevice) {
        await service.cancelFutureLetter(id);
        return;
      }
      if (await service.requestPermission()) {
        await service.scheduleFutureLetter(reminder);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.futureLetterReminderFailed)),
        );
      }
    }
  }

  Future<void> _attachImage() async {
    final id = _savedId;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).journalSaveBeforeImage),
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
      JournalImageResult.success =>
        AppLocalizations.of(context).journalImageSaved,
      JournalImageResult.tooLarge =>
        AppLocalizations.of(context).journalImageTooLarge,
      JournalImageResult.unsupported =>
        AppLocalizations.of(context).journalImageUnsupported,
      JournalImageResult.failed =>
        AppLocalizations.of(context).journalImageUploadFailed,
      JournalImageResult.canceled => '',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  String get _entryDateLabel =>
      _fullDateLabel(widget.entry?.entryDate?.toLocal() ?? _vietnamToday());

  String get _writingDateLabel =>
      AppLocalizations.of(context).journalWritingDate(
        _fullDateLabel(widget.entry?.createdAt.toLocal() ?? DateTime.now()),
      );

  String _fullDateLabel(DateTime value) =>
      AppLocalizations.of(context).journalFullDate(
        value.day.toString().padLeft(2, '0'),
        value.month.toString().padLeft(2, '0'),
        value.year,
      );

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
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 14, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: strings.back,
          ),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          TextButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.check_rounded),
            label: Text(strings.save),
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
  });

  final List<JournalMedia> media;
  final bool enabled;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image_outlined, size: 18, color: MuseColors.teal),
            const SizedBox(width: 7),
            Text(
              media.isEmpty
                  ? strings.journalImageAttach
                  : strings.journalImagesInEntry,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: enabled ? onAdd : null,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(strings.journalImageAdd),
            ),
          ],
        ),
        if (media.isNotEmpty) ...[
          const SizedBox(height: 10),
          _FilmStrip(media: media),
          const SizedBox(height: 8),
          Text(
            strings.journalImageSwipeHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MuseColors.mutedInk,
              fontStyle: FontStyle.italic,
            ),
          ),
        ] else
          Text(
            strings.journalImageAddLater,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _FilmStrip extends StatelessWidget {
  const _FilmStrip({required this.media});

  final List<JournalMedia> media;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(
        context,
      ).journalFilmStripSemantics(media.length),
      child: Container(
        height: 178,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: MuseColors.teal.withValues(alpha: .14)),
          boxShadow: [
            BoxShadow(
              color: MuseColors.teal.withValues(alpha: .08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: media.length,
            separatorBuilder: (_, _) => const SizedBox(width: 2),
            itemBuilder:
                (context, index) =>
                    _FilmFrame(media: media[index], index: index),
          ),
        ),
      ),
    );
  }
}

class _FilmFrame extends ConsumerWidget {
  const _FilmFrame({required this.media, required this.index});

  final JournalMedia media;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedUrl = ref.watch(journalMediaUrlProvider(media.storagePath));
    return Semantics(
      label: AppLocalizations.of(context).journalImageSemantics(index + 1),
      image: true,
      child: SizedBox(
        width: 148,
        height: 158,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.symmetric(
              vertical: BorderSide(
                color: MuseColors.teal.withValues(alpha: .12),
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 19, 12, 19),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: MuseColors.mint.withValues(alpha: .55),
                        border: Border.all(
                          color: MuseColors.teal.withValues(alpha: .12),
                        ),
                      ),
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
                              errorBuilder:
                                  (_, _, _) => const _MediaPlaceholder(
                                    icon: Icons.broken_image_outlined,
                                  ),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 7,
                left: 9,
                right: 9,
                child: _FilmSprocketRow(),
              ),
              const Positioned(
                bottom: 7,
                left: 9,
                right: 9,
                child: _FilmSprocketRow(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilmSprocketRow extends StatelessWidget {
  const _FilmSprocketRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var index = 0; index < 4; index++)
          SizedBox(
            width: 16,
            height: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: MuseColors.sky.withValues(alpha: .38),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }
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
