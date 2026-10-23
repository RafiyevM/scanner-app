import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner/src/auth/auth_repository.dart';
import 'package:qr_scanner/src/auth/auth_session.dart';
import 'package:qr_scanner/src/auth/local_auth_repository.dart';
import 'package:qr_scanner/src/state/login_view_model.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.result);

  AuthResult result;
  int calls = 0;

  @override
  Future<AuthResult> signIn({
    required String username,
    required String password,
  }) async {
    calls++;
    return result;
  }
}

class DeferredAuthRepository implements AuthRepository {
  final Completer<AuthResult> completer = Completer<AuthResult>();

  @override
  Future<AuthResult> signIn({
    required String username,
    required String password,
  }) {
    return completer.future;
  }
}

void main() {
  group('LocalAuthRepository', () {
    const repository = LocalAuthRepository(
      username: 'test',
      password: 'test',
    );

    test('accepts the demo credentials', () async {
      final result = await repository.signIn(
        username: 'test',
        password: 'test',
      );

      expect(result, isA<AuthSuccess>());
      expect((result as AuthSuccess).session.username, 'test');
      expect(result.session.token, isNull);
    });

    test('accepts a case-insensitive username', () async {
      final result = await repository.signIn(
        username: 'TEST',
        password: 'test',
      );

      expect(result, isA<AuthSuccess>());
    });

    test('rejects an incorrect password', () async {
      final result = await repository.signIn(
        username: 'test',
        password: 'wrong',
      );

      expect(result, isA<AuthFailure>());
      expect(
        (result as AuthFailure).type,
        AuthFailureType.invalidCredentials,
      );
    });

    test('rejects blank credentials', () async {
      final result = await repository.signIn(username: '   ', password: '');

      expect(result, isA<AuthFailure>());
      expect((result as AuthFailure).type, AuthFailureType.missingFields);
    });
  });

  group('LoginViewModel', () {
    test('rejects blank credentials without calling the repository', () async {
      final repository = FakeAuthRepository(
        const AuthFailure(AuthFailureType.failed),
      );
      final viewModel = LoginViewModel(repository);

      final signedIn = await viewModel.signIn('  ', '');

      expect(signedIn, isFalse);
      expect(viewModel.state, isA<LoginError>());
      expect(repository.calls, 0);
    });

    test('exposes a provisional loading state', () async {
      final repository = DeferredAuthRepository();
      final viewModel = LoginViewModel(repository);

      final future = viewModel.signIn('test', 'test');
      expect(viewModel.state, isA<LoginLoading>());

      repository.completer.complete(
        const AuthSuccess(AuthSession(username: 'test')),
      );
      await future;

      expect(viewModel.state, isA<LoginIdle>());
    });

    test('stores the session on success', () async {
      final repository = FakeAuthRepository(
        const AuthSuccess(AuthSession(username: 'test')),
      );
      final viewModel = LoginViewModel(repository);

      final signedIn = await viewModel.signIn('test', 'test');

      expect(signedIn, isTrue);
      expect(viewModel.session?.username, 'test');
      expect(repository.calls, 1);
    });

    test('reports a failure message', () async {
      final viewModel = LoginViewModel(
        FakeAuthRepository(
          const AuthFailure(AuthFailureType.invalidCredentials),
        ),
      );

      final signedIn = await viewModel.signIn('test', 'wrong');

      expect(signedIn, isFalse);
      expect(viewModel.state, isA<LoginError>());
      expect(
        (viewModel.state as LoginError).type,
        AuthFailureType.invalidCredentials,
      );
      expect(viewModel.session, isNull);
    });

    test('clearError returns to idle', () async {
      final viewModel = LoginViewModel(
        FakeAuthRepository(
          const AuthFailure(AuthFailureType.invalidCredentials),
        ),
      );

      await viewModel.signIn('test', 'wrong');
      expect(viewModel.state, isA<LoginError>());

      viewModel.clearError();

      expect(viewModel.state, isA<LoginIdle>());
    });
  });
}
