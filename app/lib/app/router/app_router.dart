import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/router/mvp_shell.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/presentation/sign_in_screen.dart';
import 'package:musemend/features/checkin/presentation/reflect_screen.dart';
import 'package:musemend/features/journals/presentation/journal_screen.dart';
import 'package:musemend/features/library/presentation/library_screen.dart';
import 'package:musemend/features/notifications/application/notification_providers.dart';
import 'package:musemend/features/onboarding/application/onboarding_providers.dart';
import 'package:musemend/features/onboarding/presentation/onboarding_screen.dart';
import 'package:musemend/features/profile/presentation/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authSessionProvider);
  final onboarding = ref.watch(onboardingProfileProvider);
  final initialNotificationJournalId = ref.watch(
    initialNotificationJournalIdProvider,
  );
  final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = auth.isLoading;
      final isSignedIn = auth.asData?.value != null;
      final isAuthRoute = state.matchedLocation == '/sign-in';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      final isSplash = state.matchedLocation == '/splash';

      if (isLoading) return isSplash ? null : '/splash';
      if (!isSignedIn) return isAuthRoute ? null : '/sign-in';
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
        builder: (context, state) => const SignInScreen(),
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
