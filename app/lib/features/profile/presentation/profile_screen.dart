import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/notifications/application/notification_providers.dart';
import 'package:musemend/features/notifications/domain/inbox_notification.dart';
import 'package:musemend/features/profile/application/profile_providers.dart';
import 'package:musemend/features/profile/domain/account_overview.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).asData?.value;
    final operation = ref.watch(authControllerProvider);
    final overview = ref.watch(accountOverviewProvider);
    final notifications = ref.watch(notificationInboxProvider);
    return ColoredBox(
      color:
          Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : MuseColors.mint,
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
                            'Nhắc thư tương lai trên thiết bị',
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.tune_rounded),
                          title: const Text('Chỉnh sửa hồ sơ và cài đặt'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _editSettings(context, ref, data),
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
                                        context.go(
                                          Uri(
                                            path: '/journal',
                                            queryParameters: {
                                              'open': items[index].journalId,
                                            },
                                          ).toString(),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Quyền riêng tư'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap:
                        () => _showInformation(
                          context,
                          title: 'Quyền riêng tư',
                          body:
                              'Nhật ký được lưu riêng tư trên Supabase và chỉ '
                              'tài khoản của bạn được đọc qua RLS. MuseMend không '
                              'đưa nội dung thư lên thông báo màn hình khóa. Bản '
                              'MVP chưa mã hóa đầu-cuối và chưa cung cấp xuất dữ liệu.',
                        ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Điều khoản và giới hạn'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap:
                        () => _showInformation(
                          context,
                          title: 'Điều khoản và giới hạn',
                          body:
                              'MuseMend là công cụ hỗ trợ phản tư, không chẩn đoán '
                              'và không thay thế chuyên gia y tế hoặc sức khỏe tâm '
                              'thần. Nếu bạn đang gặp nguy hiểm tức thời, hãy liên '
                              'hệ dịch vụ khẩn cấp hoặc một người đáng tin cậy.',
                        ),
                  ),
                ],
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
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed:
                  operation.isLoading
                      ? null
                      : () => _requestDeletion(context, ref),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Yêu cầu xóa tài khoản'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSettings(
    BuildContext context,
    WidgetRef ref,
    AccountOverview overview,
  ) async {
    final draft = await showDialog<_SettingsDraft>(
      context: context,
      builder: (_) => _SettingsDialog(overview: overview),
    );
    if (draft == null) return;
    final saved = await ref
        .read(accountOverviewProvider.notifier)
        .save(
          displayName: draft.displayName,
          cloudName: draft.cloudName,
          themeMode: draft.themeMode,
          soundEnabled: draft.soundEnabled,
          notificationEnabled: draft.notificationEnabled,
        );
    if (saved && !draft.notificationEnabled) {
      try {
        await ref.read(notificationServiceProvider).cancelAll();
      } catch (_) {
        // Server settings remain authoritative if local cancellation fails.
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Đã cập nhật cài đặt.' : 'Chưa thể cập nhật cài đặt.',
        ),
      ),
    );
  }

  Future<void> _requestDeletion(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed != true) return;
    final requested =
        await ref.read(accountOverviewProvider.notifier).requestDeletion();
    if (!requested) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa thể gửi yêu cầu xóa tài khoản.')),
      );
      return;
    }
    try {
      await ref.read(notificationServiceProvider).cancelAll();
    } catch (_) {
      // Account deletion is server-side and must not depend on local state.
    }
    await ref.read(authControllerProvider.notifier).signOut();
  }

  void _showInformation(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({required this.overview});

  final AccountOverview overview;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late final _displayName = TextEditingController(
    text: widget.overview.profile.displayName ?? '',
  );
  late final _cloudName = TextEditingController(
    text: widget.overview.settings.cloudName,
  );
  late String _themeMode = widget.overview.settings.themeMode;
  late bool _soundEnabled = widget.overview.settings.soundEnabled;
  late bool _notificationEnabled = widget.overview.settings.notificationEnabled;

  @override
  void dispose() {
    _displayName.dispose();
    _cloudName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hồ sơ và cài đặt'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _displayName,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Tên hiển thị'),
            ),
            TextField(
              controller: _cloudName,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Tên của Mây'),
            ),
            DropdownButtonFormField<String>(
              value: _themeMode,
              decoration: const InputDecoration(labelText: 'Giao diện'),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('Theo hệ thống')),
                DropdownMenuItem(value: 'light', child: Text('Sáng')),
                DropdownMenuItem(value: 'dark', child: Text('Tối')),
              ],
              onChanged: (value) => setState(() => _themeMode = value!),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _soundEnabled,
              onChanged: (value) => setState(() => _soundEnabled = value),
              title: const Text('Âm thanh'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _notificationEnabled,
              onChanged:
                  (value) => setState(() => _notificationEnabled = value),
              title: const Text('Thông báo'),
              subtitle: const Text('Nhắc thư tương lai trên thiết bị'),
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
              _cloudName.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(
                    context,
                    _SettingsDraft(
                      displayName: _nullable(_displayName.text),
                      cloudName: _cloudName.text.trim(),
                      themeMode: _themeMode,
                      soundEnabled: _soundEnabled,
                      notificationEnabled: _notificationEnabled,
                    ),
                  ),
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _SettingsDraft {
  const _SettingsDraft({
    required this.displayName,
    required this.cloudName,
    required this.themeMode,
    required this.soundEnabled,
    required this.notificationEnabled,
  });

  final String? displayName;
  final String cloudName;
  final String themeMode;
  final bool soundEnabled;
  final bool notificationEnabled;
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xóa tài khoản vĩnh viễn?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yêu cầu này khóa tài khoản ngay, ẩn nhật ký và đưa tệp riêng tư '
            'vào hàng đợi xóa. Thao tác hiện không thể hoàn tác.',
          ),
          const SizedBox(height: 16),
          const Text('Nhập XÓA để xác nhận:'),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmation,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'XÓA'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed:
              _confirmation.text.trim() == 'XÓA'
                  ? () => Navigator.pop(context, true)
                  : null,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Xóa tài khoản'),
        ),
      ],
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
