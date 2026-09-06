import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/checkin/application/reflect_providers.dart';
import 'package:musemend/features/notifications/application/notification_providers.dart';

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
              .save(mood: mood, energyLevel: null, note: null);
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
  final ValueChanged<Mood> onMoodSelected;

  static const _items = [
    (Icons.cloud_outlined, 'Bầu trời'),
    (Icons.auto_stories_outlined, 'Nhật ký'),
    (Icons.explore_outlined, 'Khám phá'),
    (Icons.person_outline, 'Cá nhân'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = shell.currentIndex;
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          height: 93,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .88),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: const Color(0xFFE3E3DC).withValues(alpha: .65),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var index = 0; index < 2; index++)
                Expanded(child: _item(index, selected)),
              Expanded(
                child: _MoodCloudButton(
                  onMoodSelected: onMoodSelected,
                  onTap:
                      () => shell.goBranch(
                        0,
                        initialLocation: shell.currentIndex == 0,
                      ),
                ),
              ),
              for (var index = 2; index < _items.length; index++)
                Expanded(child: _item(index, selected)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, int selected) {
    return _NavItem(
      icon: _items[index].$1,
      label: _items[index].$2,
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

  final ValueChanged<Mood> onMoodSelected;
  final VoidCallback onTap;

  @override
  State<_MoodCloudButton> createState() => _MoodCloudButtonState();
}

class _MoodCloudButtonState extends State<_MoodCloudButton> {
  bool _pressed = false;

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
    if (mood != null && mounted) widget.onMoodSelected(mood);
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
        onTap: widget.onTap,
        onLongPress: _showMoodPicker,
        child: AnimatedScale(
          scale: _pressed ? .9 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF5F929A),
              border: Border.all(
                color: Colors.white.withValues(alpha: .82),
                width: 4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Image.asset(
                'assets/illustrations/clouds/mascot-cloud.png',
                fit: BoxFit.contain,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Icon(Icons.cloud, color: Colors.white),
              ),
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
    return Semantics(
      button: true,
      label: mood.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            children: [
              Text(mood.symbol, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                mood.label,
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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color:
                      selected ? const Color(0xFFE9E1FA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  color: selected ? MuseColors.ink : MuseColors.mutedInk,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? MuseColors.ink : MuseColors.mutedInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
