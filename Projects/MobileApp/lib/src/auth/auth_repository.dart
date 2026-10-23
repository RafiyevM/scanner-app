import 'auth_session.dart';

enum AuthFailureType {
  missingFields,
  invalidCredentials,
  failed,
  timedOut,
  unreachable,
  unexpectedResponse,
}

sealed class AuthResult {
  const AuthResult();
}

final class AuthSuccess extends AuthResult {
  const AuthSuccess(this.session);

  final AuthSession session;
}

final class AuthFailure extends AuthResult {
  const AuthFailure(this.type, [this.cause]);

  final AuthFailureType type;
  final Object? cause;
}

abstract class AuthRepository {
  Future<AuthResult> signIn({
    required String username,
    required String password,
  });
}
