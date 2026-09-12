import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/features/checkin/application/reflect_providers.dart';
import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/checkin/presentation/mood_visuals.dart';
import 'package:musemend/features/notifications/application/notification_providers.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

class MvpShell extends ConsumerStatefulWidget {
  const MvpShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MvpShell> createState() => _MvpShellState();
}

class _MvpShellState extends ConsumerState<MvpShell>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final service = ref.read(notificationServiceProvider);
    _notificationSubscription = service.journalOpenRequests.listen(
      _openJournal,
    );
    final pendingJournalId = service.takePendingJournalId();
    if (pendingJournalId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openJournal(pendingJournalId),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _openJournal(String journalId) {
    if (!mounted) return;
    context.go(
      Uri(path: '/journal', queryParameters: {'open': journalId}).toString(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(reflectControllerProvider.notifier).recordAppOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: _MuseBottomNavigation(
        shell: widget.navigationShell,
        onMoodSelected: (mood) async {
          final saved = await ref
              .read(reflectControllerProvider.notifier)
              .updateMood(mood);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                saved
                    ? 'Đã ghi nhận ${mood.label.toLowerCase()}.'
                    : 'Chưa thể ghi nhận cảm xúc. Hãy thử lại.',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MuseBottomNavigation extends StatelessWidget {
  const _MuseBottomNavigation({
    required this.shell,
    required this.onMoodSelected,
  });

  final StatefulNavigationShell shell;
  final Future<void> Function(Mood mood) onMoodSelected;

  @override
  Widget build(BuildContext context) {
    final selected = shell.currentIndex;
    final strings = AppLocalizations.of(context);
    final items = [
      (Icons.auto_awesome_outlined, strings.navSky),
      (Icons.edit_note_rounded, strings.navJournal),
      (Icons.explore_outlined, strings.navExplore),
      (Icons.person_outline_rounded, strings.navProfile),
    ];
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    child: Material(
                      color: Colors.white.withValues(alpha: .91),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(
                              0xFFE3E3DC,
                            ).withValues(alpha: .55),
                          ),
                        ),
                        child: Row(
                          children: [
                            for (var index = 0; index < 2; index++)
                              Expanded(child: _item(items, index, selected)),
                            const Expanded(child: SizedBox()),
                            for (var index = 2; index < items.length; index++)
                              Expanded(child: _item(items, index, selected)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -19,
                child: _MoodCloudButton(
                  onMoodSelected: onMoodSelected,
                  onTap:
                      () => shell.goBranch(
                        0,
                        initialLocation: shell.currentIndex == 0,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(List<(IconData, String)> items, int index, int selected) {
    return _NavItem(
      icon: items[index].$1,
      label: items[index].$2,
      selected: selected == index,
      onTap:
          () => shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          ),
    );
  }
}

class _MoodCloudButton extends StatefulWidget {
  const _MoodCloudButton({required this.onMoodSelected, required this.onTap});

  final Future<void> Function(Mood mood) onMoodSelected;
  final VoidCallback onTap;

  @override
  State<_MoodCloudButton> createState() => _MoodCloudButtonState();
}

class _MoodCloudButtonState extends State<_MoodCloudButton> {
  bool _pressed = false;
  bool _saving = false;

  Future<void> _showMoodPicker() async {
    final mood = await showModalBottomSheet<Mood>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFCF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mây hôm nay đang cảm thấy thế nào?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (final value in Mood.values)
                        Expanded(
                          child: _MoodPickerOption(
                            mood: value,
                            onTap: () => Navigator.of(context).pop(value),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    if (mood == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.onMoodSelected(mood);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mây cảm xúc. Chạm để về Bầu trời, nhấn giữ để chọn cảm xúc.',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _saving ? null : widget.onTap,
        onLongPress: _saving ? null : _showMoodPicker,
        child: AnimatedScale(
          scale: _pressed ? .9 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF366672),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 9,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child:
                _saving
                    ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFEFFBFF),
                      ),
                    )
                    : const SizedBox(
                      width: 27.5,
                      height: 20,
                      child: CustomPaint(painter: _CloudOutlinePainter()),
                    ),
          ),
        ),
      ),
    );
  }
}

class _MoodPickerOption extends StatelessWidget {
  const _MoodPickerOption({required this.mood, required this.onTap});

  final Mood mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = mood.visual;
    return Semantics(
      button: true,
      label: visual.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            children: [
              SizedBox(
                width: 42,
                height: 36,
                child: Image.asset(
                  visual.assetPath,
                  cacheWidth: 128,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                visual.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloudOutlinePainter extends CustomPainter {
  const _CloudOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFFEFFBFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final path =
        Path()
          ..moveTo(size.width * .20, size.height * .82)
          ..cubicTo(
            size.width * .05,
            size.height * .82,
            size.width * .02,
            size.height * .58,
            size.width * .17,
            size.height * .48,
          )
          ..cubicTo(
            size.width * .18,
            size.height * .24,
            size.width * .39,
            size.height * .12,
            size.width * .55,
            size.height * .30,
          )
          ..cubicTo(
            size.width * .69,
            size.height * .19,
            size.width * .87,
            size.height * .32,
            size.width * .87,
            size.height * .50,
          )
          ..cubicTo(
            size.width * 1.02,
            size.height * .58,
            size.width * .96,
            size.height * .82,
            size.width * .81,
            size.height * .82,
          )
          ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CloudOutlinePainter oldDelegate) => false;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFF366672).withValues(alpha: .12);
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return const Color(0xFF366672).withValues(alpha: .07);
              }
              return Colors.transparent;
            }),
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      icon,
                      size: 22,
                      color:
                          selected
                              ? const Color(0xFF366672)
                              : MuseColors.mutedInk,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      height: 1,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          selected
                              ? const Color(0xFF366672)
                              : MuseColors.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
