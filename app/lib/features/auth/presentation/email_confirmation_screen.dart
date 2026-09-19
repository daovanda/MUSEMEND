import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/domain/auth_callback_token.dart';
import 'package:musemend/features/auth/presentation/auth_web_notice.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

class EmailConfirmationScreen extends ConsumerStatefulWidget {
  const EmailConfirmationScreen({this.callbackUri, super.key});

  final Uri? callbackUri;

  @override
  ConsumerState<EmailConfirmationScreen> createState() =>
      _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState
    extends ConsumerState<EmailConfirmationScreen> {
  var _isVerifying = false;
  bool? _tokenVerified;

  Future<void> _verify(AuthCallbackToken token) async {
    setState(() => _isVerifying = true);
    final verified = await ref
        .read(authControllerProvider.notifier)
        .verifyEmailConfirmation(tokenHash: token.hash);
    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _tokenVerified = verified;
    });
    if (verified) context.replace('/email-confirmed');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_tokenVerified == true) {
      return AuthWebNotice(
        title: strings.authEmailConfirmedTitle,
        body: strings.authEmailConfirmedBody,
        icon: Icons.mark_email_read_outlined,
      );
    }
    if (_tokenVerified == false) {
      return AuthWebNotice(
        title: strings.authLinkInvalidTitle,
        body: strings.authLinkInvalidBody,
        icon: Icons.link_off_rounded,
      );
    }

    final callback = AuthCallbackToken.fromUri(widget.callbackUri ?? Uri.base);
    if (callback?.type == AuthCallbackType.email) {
      return AuthWebNotice(
        title: strings.authConfirmEmailTitle,
        body: strings.authConfirmEmailPrompt,
        icon: Icons.mark_email_read_outlined,
        actionLabel: strings.authConfirmEmailAction,
        onAction: () => _verify(callback!),
        isLoading: _isVerifying,
      );
    }

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
          (_, _) => AuthWebNotice(
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
