import 'auth_repository.dart';
import 'auth_session.dart';

/// Demo-only local sign-in. This is not production authentication.
class LocalAuthRepository implements AuthRepository {
  const LocalAuthRepository({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;

  @override
  Future<AuthResult> signIn({
    required String username,
    required String password,
  }) async {
    final enteredUsername = username.trim();
    if (enteredUsername.isEmpty || password.isEmpty) {
      return const AuthFailure(AuthFailureType.missingFields);
    }

    if (enteredUsername.toLowerCase() == this.username.toLowerCase() &&
        password == this.password) {
      return AuthSuccess(AuthSession(username: enteredUsername));
    }

    return const AuthFailure(AuthFailureType.invalidCredentials);
  }
}
