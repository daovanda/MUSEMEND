import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/router/mvp_shell.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/presentation/sign_in_screen.dart';
import 'package:musemend/features/auth/presentation/email_confirmation_screen.dart';
import 'package:musemend/features/auth/presentation/web_auth_landing_screen.dart';
import 'package:musemend/features/auth/presentation/public_auth_portal_screen.dart';
import 'package:musemend/features/checkin/presentation/reflect_screen.dart';
import 'package:musemend/features/journals/presentation/journal_screen.dart';
import 'package:musemend/features/library/presentation/library_screen.dart';
import 'package:musemend/features/notifications/application/notification_providers.dart';
import 'package:musemend/features/onboarding/application/onboarding_providers.dart';
import 'package:musemend/features/onboarding/presentation/onboarding_screen.dart';
import 'package:musemend/features/auth/presentation/password_reset_screen.dart';
import 'package:musemend/features/profile/presentation/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  if (ref.watch(publicAuthPortalModeProvider)) {
    final router = GoRouter(
      initialLocation: '/',
      errorBuilder: (context, state) => const WebAuthLandingScreen(),
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) =>
                  const PublicAuthPortalScreen(page: PublicAuthPortalPage.home),
        ),
        GoRoute(
          path: '/privacy',
          builder:
              (context, state) => const PublicAuthPortalScreen(
                page: PublicAuthPortalPage.privacy,
              ),
        ),
        GoRoute(
          path: '/terms',
          builder:
              (context, state) => const PublicAuthPortalScreen(
                page: PublicAuthPortalPage.terms,
              ),
        ),
        GoRoute(
          path: '/email-confirmed',
          builder:
              (context, state) =>
                  EmailConfirmationScreen(callbackUri: state.uri),
        ),
        GoRoute(
          path: '/reset-password',
          builder:
              (context, state) => PasswordResetScreen(callbackUri: state.uri),
        ),
      ],
    );
    ref.onDispose(router.dispose);
    return router;
  }

  // Keep an explicitly opened OTP route on Flutter Web for local QA. Native
  // launches still begin at splash, and root web launches retain that behavior.
  final initialLocation =
      kIsWeb && Uri.base.path.isNotEmpty && Uri.base.path != '/'
          ? Uri.base.path
          : '/splash';
  final router = GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      final auth = ref.read(authSessionProvider);
      final onboarding = ref.read(onboardingProfileProvider);
      final initialNotificationJournalId = ref.read(
        initialNotificationJournalIdProvider,
      );
      final isLoading = auth.isLoading;
      final isSignedIn = auth.asData?.value != null;
      final isAuthRoute = state.matchedLocation == '/sign-in';
      final isPasswordResetRoute = state.matchedLocation == '/reset-password';
      final isEmailConfirmationRoute =
          state.matchedLocation == '/confirm-email';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      final isSplash = state.matchedLocation == '/splash';

      if (isLoading) {
        return isSplash || isPasswordResetRoute || isEmailConfirmationRoute
            ? null
            : '/splash';
      }
      if (!isSignedIn) {
        return isAuthRoute || isPasswordResetRoute || isEmailConfirmationRoute
            ? null
            : '/sign-in';
      }
      if (isPasswordResetRoute || isEmailConfirmationRoute) return null;
      if (onboarding.isLoading) return isSplash ? null : '/splash';
      if (onboarding.hasError) {
        return isOnboardingRoute ? null : '/onboarding';
      }
      final needsOnboarding = onboarding.asData?.value?.isCompleted != true;
      if (needsOnboarding) {
        return isOnboardingRoute ? null : '/onboarding';
      }
      if (isAuthRoute || isOnboardingRoute || isSplash) {
        return initialNotificationJournalId == null
            ? '/reflect'
            : Uri(
              path: '/journal',
              queryParameters: {'open': initialNotificationJournalId},
            ).toString();
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder:
            (context, state) => SignInScreen(
              showPasswordResetSuccess:
                  state.uri.queryParameters['reset'] == 'success',
            ),
      ),
      GoRoute(
        path: '/reset-password',
        builder:
            (context, state) => PasswordResetScreen(
              callbackUri: state.uri,
              initialEmail: state.extra as String?,
            ),
      ),
      GoRoute(
        path: '/confirm-email',
        builder:
            (context, state) => EmailConfirmationScreen(
              callbackUri: state.uri,
              initialEmail: state.extra as String?,
            ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MvpShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reflect',
                builder: (context, state) => const ReflectScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journal',
                builder:
                    (context, state) => JournalScreen(
                      requestedEntryId: state.uri.queryParameters['open'],
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  // Keep the router instance stable while auth providers move from loading to
  // data. Recreating GoRouter during sign-up/reset navigation sends the user
  // back through initialLocation before the OTP screen can remain visible.
  ref.listen(authSessionProvider, (_, _) => router.refresh());
  ref.listen(onboardingProfileProvider, (_, _) => router.refresh());
  ref.listen(initialNotificationJournalIdProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
