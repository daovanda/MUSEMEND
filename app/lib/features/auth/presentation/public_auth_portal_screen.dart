import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

/// Public, static information served by the Vercel auth portal.
///
/// This intentionally has no authentication controls or application data. It
/// gives the Google OAuth consent screen a public home, privacy, and terms
/// destination without exposing the native application on the web.
enum PublicAuthPortalPage { home, privacy, terms }

class PublicAuthPortalScreen extends StatelessWidget {
  const PublicAuthPortalScreen({required this.page, super.key});

  final PublicAuthPortalPage page;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isHome = page == PublicAuthPortalPage.home;
    final title = switch (page) {
      PublicAuthPortalPage.home => strings.webAuthHomeTitle,
      PublicAuthPortalPage.privacy => strings.profilePrivacyTitle,
      PublicAuthPortalPage.terms => strings.profileTermsTitle,
    };
    final body = switch (page) {
      PublicAuthPortalPage.home => strings.webAuthHomeBody,
      PublicAuthPortalPage.privacy =>
        '${strings.profilePrivacyBody}\n\n${strings.webAuthPrivacyGoogleData}',
      PublicAuthPortalPage.terms => strings.profileTermsBody,
    };

    return Scaffold(
      backgroundColor: MuseColors.cream,
      body: MusePageBackground(
        accent: MuseColors.mint,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: MuseGlassCard(
                  padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: MuseBrandMark(width: 112, height: 78),
                      ),
                      const SizedBox(height: 18),
                      Icon(
                        switch (page) {
                          PublicAuthPortalPage.home =>
                            Icons.auto_stories_outlined,
                          PublicAuthPortalPage.privacy =>
                            Icons.privacy_tip_outlined,
                          PublicAuthPortalPage.terms =>
                            Icons.health_and_safety_outlined,
                        },
                        color: MuseColors.teal,
                        size: 38,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: MuseColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: MuseColors.ink.withValues(alpha: .78),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isHome)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            TextButton(
                              onPressed: () => context.go('/privacy'),
                              child: Text(strings.profilePrivacyTitle),
                            ),
                            TextButton(
                              onPressed: () => context.go('/terms'),
                              child: Text(strings.profileTermsTitle),
                            ),
                          ],
                        )
                      else
                        TextButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: Text(strings.webAuthBackHome),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
