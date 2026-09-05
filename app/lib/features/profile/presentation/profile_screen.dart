import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/notifications/application/notification_providers.dart';
import 'package:musemend/features/notifications/domain/inbox_notification.dart';
import 'package:musemend/features/profile/application/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).asData?.value;
    final operation = ref.watch(authControllerProvider);
    final overview = ref.watch(accountOverviewProvider);
    final notifications = ref.watch(notificationInboxProvider);
    return ColoredBox(
      color: MuseColors.mint,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Hồ sơ', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            overview.when(
              loading:
                  () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              error:
                  (_, _) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.cloud_off_rounded),
                      title: const Text('Chưa thể tải hồ sơ'),
                      trailing: IconButton(
                        onPressed:
                            () => ref.invalidate(accountOverviewProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ),
                  ),
              data:
                  (data) => Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_rounded),
                          ),
                          title: Text(
                            data.profile.displayName ?? 'Bạn của Muse',
                          ),
                          subtitle: Text(session?.email ?? 'Email được bảo vệ'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.cloud_rounded),
                          title: const Text('Tên của Mây'),
                          trailing: Text(data.settings.cloudName),
                        ),
                        SwitchListTile(
                          value: data.settings.notificationEnabled,
                          onChanged: null,
                          secondary: const Icon(Icons.notifications_outlined),
                          title: const Text('Thông báo'),
                          subtitle: const Text(
                            'Chỉnh sửa sẽ có ở bước Settings',
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Thông báo trong ứng dụng',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            notifications.when(
              loading:
                  () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              error:
                  (_, _) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.cloud_off_rounded),
                      title: const Text('Chưa thể tải thông báo'),
                      trailing: IconButton(
                        onPressed:
                            () => ref.invalidate(notificationInboxProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ),
                  ),
              data:
                  (items) =>
                      items.isEmpty
                          ? const Card(
                            child: ListTile(
                              leading: Icon(Icons.notifications_none_rounded),
                              title: Text('Chưa có thông báo mới'),
                              subtitle: Text(
                                'Thư đến hạn sẽ xuất hiện tại đây.',
                              ),
                            ),
                          )
                          : Card(
                            child: Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < items.length;
                                  index++
                                )
                                  _NotificationTile(
                                    notification: items[index],
                                    showDivider: index < items.length - 1,
                                    onTap: () async {
                                      final opened = await ref
                                          .read(
                                            notificationInboxProvider.notifier,
                                          )
                                          .open(items[index]);
                                      if (opened && context.mounted) {
                                        context.go('/journal');
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed:
                  operation.isLoading
                      ? null
                      : () =>
                          ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.showDivider,
    required this.onTap,
  });

  final InboxNotification notification;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final local = notification.scheduledFor.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(
            notification.isUnread
                ? Icons.mark_email_unread_rounded
                : Icons.drafts_rounded,
          ),
          title: const Text('Lá thư tương lai đã đến hạn'),
          subtitle: Text('Hẹn mở ngày $date'),
          trailing:
              notification.isUnread
                  ? const Icon(Icons.circle, size: 10)
                  : const Icon(Icons.chevron_right_rounded),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
