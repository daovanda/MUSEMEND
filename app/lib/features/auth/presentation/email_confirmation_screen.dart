import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/presentation/auth_web_notice.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

class EmailConfirmationScreen extends ConsumerWidget {
  const EmailConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final session = ref.watch(authSessionProvider);
    return session.when(
      data: (value) {
        if (value == null) {
          return AuthWebNotice(
            title: strings.authLinkInvalidTitle,
            body: strings.authLinkInvalidBody,
            icon: Icons.link_off_rounded,
          );
        }
        return AuthWebNotice(
          title: strings.authEmailConfirmedTitle,
          body: strings.authEmailConfirmedBody,
          icon: Icons.mark_email_read_outlined,
        );
      },
      error:
          (error, stackTrace) => AuthWebNotice(
            title: strings.authLinkInvalidTitle,
            body: strings.authLinkInvalidBody,
            icon: Icons.link_off_rounded,
          ),
      loading:
          () => Scaffold(
            backgroundColor: MuseColors.cream,
            body: MusePageBackground(
              accent: MuseColors.mint,
              child: const Center(
                child: CircularProgressIndicator(color: MuseColors.teal),
              ),
            ),
          ),
    );
  }
}
