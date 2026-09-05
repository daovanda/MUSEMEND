import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/profile/application/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).asData?.value;
    final operation = ref.watch(authControllerProvider);
    final overview = ref.watch(accountOverviewProvider);
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
