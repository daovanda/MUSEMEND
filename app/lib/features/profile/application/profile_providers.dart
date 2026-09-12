import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/core/supabase/supabase_client_provider.dart';
import 'package:musemend/features/profile/data/supabase_profile_repository.dart';
import 'package:musemend/features/profile/domain/account_overview.dart';
import 'package:musemend/features/profile/domain/profile_repository.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/core/localization/supported_locales.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(ref.watch(supabaseClientProvider));
});

final accountOverviewProvider =
    AsyncNotifierProvider<AccountOverviewController, AccountOverview>(
      AccountOverviewController.new,
    );

final appThemeModeProvider =
    AsyncNotifierProvider<AppThemeModeController, ThemeMode>(
      AppThemeModeController.new,
    );

final appLanguageCodeProvider =
    AsyncNotifierProvider<AppLanguageCodeController, String?>(
      AppLanguageCodeController.new,
    );

class AccountOverviewController extends AsyncNotifier<AccountOverview> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  Future<AccountOverview> build() async {
    final userId = ref.watch(authSessionProvider).value?.userId;
    if (userId == null) {
      throw StateError('Authenticated user required.');
    }
    return _repository.loadOverview();
  }

  Future<bool> save({
    required String? displayName,
    required String cloudName,
    required String themeMode,
    required bool soundEnabled,
    required bool notificationEnabled,
    required String? languageCode,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.updateProfileSettings(
        displayName: displayName,
        cloudName: cloudName,
        themeMode: themeMode,
        soundEnabled: soundEnabled,
        notificationEnabled: notificationEnabled,
        languageCode: languageCode,
      );
      state = AsyncData(await _repository.loadOverview());
      ref
          .read(appThemeModeProvider.notifier)
          .applyStoredMode(state.requireValue.settings.themeMode);
      ref
          .read(appLanguageCodeProvider.notifier)
          .applyStoredLanguage(state.requireValue.settings.languageCode);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> requestDeletion() async {
    try {
      await _repository.requestAccountDeletion();
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

class AppLanguageCodeController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final userId = ref.watch(authSessionProvider).value?.userId;
    if (userId == null) return null;
    final overview = await ref.watch(profileRepositoryProvider).loadOverview();
    return _sanitizeStoredLanguage(overview.settings.languageCode);
  }

  void applyStoredLanguage(String? value) {
    state = AsyncData(_sanitizeStoredLanguage(value));
  }

  String? _sanitizeStoredLanguage(String? value) {
    if (value == null) return null;
    return supportedLanguageCodes.contains(value.toLowerCase())
        ? value.toLowerCase()
        : fallbackLanguageCode;
  }
}

class AppThemeModeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final userId = ref.watch(authSessionProvider).value?.userId;
    if (userId == null) return ThemeMode.light;
    final overview = await ref.watch(profileRepositoryProvider).loadOverview();
    return _fromStored(overview.settings.themeMode);
  }

  void applyStoredMode(String value) {
    state = AsyncData(_fromStored(value));
  }

  ThemeMode _fromStored(String value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.light,
    _ => ThemeMode.light,
  };
}
