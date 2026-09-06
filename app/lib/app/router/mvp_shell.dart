import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            label: 'Reflect',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
