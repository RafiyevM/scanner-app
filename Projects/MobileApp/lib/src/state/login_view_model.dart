import 'package:flutter/foundation.dart';

import '../auth/auth_repository.dart';
import '../auth/auth_session.dart';

sealed class LoginUiState {
  const LoginUiState();
}

final class LoginIdle extends LoginUiState {
  const LoginIdle();
}

final class LoginLoading extends LoginUiState {
  const LoginLoading();
}

final class LoginError extends LoginUiState {
  const LoginError(this.type);

  final AuthFailureType type;
}

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._repository);

  final AuthRepository _repository;

  LoginUiState _state = const LoginIdle();
  LoginUiState get state => _state;

  AuthSession? _session;
  AuthSession? get session => _session;

  bool _busy = false;
  bool _disposed = false;

  Future<bool> signIn(String username, String password) async {
    if (_busy) {
      return false;
    }
    if (username.trim().isEmpty || password.isEmpty) {
      _setState(const LoginError(AuthFailureType.missingFields));
      return false;
    }

    _busy = true;
    _setState(const LoginLoading());

    AuthResult result;
    try {
      result = await _repository.signIn(
        username: username,
        password: password,
      );
    } catch (_) {
      result = const AuthFailure(AuthFailureType.failed);
    }
    _busy = false;

    if (_disposed) {
      return false;
    }

    switch (result) {
      case final AuthSuccess success:
        _session = success.session;
        _setState(const LoginIdle());
        return true;

      case final AuthFailure failure:
        _setState(LoginError(failure.type));
        return false;
    }
  }

  void clearError() {
    if (_state is LoginError) {
      _setState(const LoginIdle());
    }
  }

  void _setState(LoginUiState state) {
    if (_disposed) {
      return;
    }
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
