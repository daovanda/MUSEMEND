enum AuthFailureCode {
  invalidCredentials,
  emailAlreadyRegistered,
  emailNotConfirmed,
  emailConfirmationFailed,
  weakPassword,
  passwordResetFailed,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final AuthFailureCode code;
}
