enum AuthCallbackType { email, recovery }

class AuthCallbackToken {
  const AuthCallbackToken({required this.hash, required this.type});

  final String hash;
  final AuthCallbackType type;

  static AuthCallbackToken? fromUri(Uri uri) {
    final fragment = uri.fragment;
    if (fragment.isEmpty) return null;

    try {
      final parameters = Uri.splitQueryString(fragment);
      final hash = parameters['token_hash']?.trim();
      final type = switch (parameters['type']) {
        'email' => AuthCallbackType.email,
        'recovery' => AuthCallbackType.recovery,
        _ => null,
      };
      if (hash == null || hash.isEmpty || type == null) return null;
      return AuthCallbackToken(hash: hash, type: type);
    } on FormatException {
      return null;
    }
  }
}
