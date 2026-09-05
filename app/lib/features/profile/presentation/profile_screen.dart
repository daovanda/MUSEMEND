import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).asData?.value;
    final operation = ref.watch(authControllerProvider);
    return ColoredBox(
      color: MuseColors.mint,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Hồ sơ', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                title: const Text('Tài khoản MuseMend'),
                subtitle: Text(session?.email ?? 'Email được bảo vệ'),
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
