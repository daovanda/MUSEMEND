import 'package:musemend/features/auth/domain/auth_failure.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

String authErrorMessage(AppLocalizations strings, Object error) {
  if (error is! AuthFailure) {
    return strings.authNetworkError;
  }
  return switch (error.code) {
    AuthFailureCode.invalidCredentials => strings.authInvalidCredentials,
    AuthFailureCode.emailAlreadyRegistered =>
      strings.authEmailAlreadyRegistered,
    AuthFailureCode.emailNotConfirmed => strings.authEmailNotConfirmed,
    AuthFailureCode.weakPassword => strings.authWeakPassword,
    AuthFailureCode.unknown => strings.authNetworkError,
  };
}
