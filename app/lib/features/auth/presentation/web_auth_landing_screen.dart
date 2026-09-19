import 'package:flutter/material.dart';
import 'package:musemend/features/auth/presentation/auth_web_notice.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

class WebAuthLandingScreen extends StatelessWidget {
  const WebAuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AuthWebNotice(
      title: strings.appTitle,
      body: strings.webAuthLandingBody,
      icon: Icons.mark_email_read_outlined,
    );
  }
}
