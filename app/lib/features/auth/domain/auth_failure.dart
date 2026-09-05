enum AuthFailureCode {
  invalidCredentials,
  emailAlreadyRegistered,
  emailNotConfirmed,
  weakPassword,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final AuthFailureCode code;
}
