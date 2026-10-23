import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_repository.dart';
import 'auth_session.dart';

/// Provisional auth contract: POST {baseUrl}auth/login.
/// Replace this implementation once the real auth contract is known.
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<AuthResult> signIn({
    required String username,
    required String password,
  }) async {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final uri = Uri.parse('${normalizedBase}auth/login');

    try {
      final response = await _client
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, String>{
              'username': username,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const AuthFailure(AuthFailureType.invalidCredentials);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const AuthFailure(AuthFailureType.failed);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const AuthFailure(AuthFailureType.unexpectedResponse);
      }

      final token = decoded['token'];
      if (token is! String || token.isEmpty) {
        return const AuthFailure(AuthFailureType.unexpectedResponse);
      }

      return AuthSuccess(AuthSession(username: username.trim(), token: token));
    } on TimeoutException {
      return const AuthFailure(AuthFailureType.timedOut);
    } on http.ClientException {
      return const AuthFailure(AuthFailureType.unreachable);
    } on FormatException {
      return const AuthFailure(AuthFailureType.unexpectedResponse);
    } catch (_) {
      return const AuthFailure(AuthFailureType.unexpectedResponse);
    }
  }

  void dispose() => _client.close();
}
