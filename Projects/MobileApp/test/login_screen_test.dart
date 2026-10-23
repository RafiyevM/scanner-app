import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner/l10n/app_localizations.dart';
import 'package:qr_scanner/src/auth/auth_repository.dart';
import 'package:qr_scanner/src/auth/auth_session.dart';
import 'package:qr_scanner/src/ui/login_screen.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> signIn({
    required String username,
    required String password,
  }) async {
    if (username.trim().toLowerCase() == 'test' && password == 'test') {
      return AuthSuccess(AuthSession(username: username.trim()));
    }
    return const AuthFailure(AuthFailureType.invalidCredentials);
  }
}

Widget wrap({
  required ValueChanged<AuthSession> onSignedIn,
  bool showDemoHint = true,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: LoginScreen(
      authRepository: FakeAuthRepository(),
      locale: locale,
      onLocaleChanged: (_) {},
      onSignedIn: onSignedIn,
      showDemoHint: showDemoHint,
      demoUsername: 'test',
      demoPassword: 'test',
    ),
  );
}

void main() {
  group('LoginScreen', () {
    testWidgets('renders the sign-in interface', (tester) async {
      await tester.pumpWidget(wrap(onSignedIn: (_) {}));

      expect(find.text('Scanner'), findsOneWidget);
      expect(find.text('Sign in to start scanning.'), findsOneWidget);
      expect(find.byKey(const Key('login-username')), findsOneWidget);
      expect(find.byKey(const Key('login-password')), findsOneWidget);
      expect(find.byKey(const Key('login-submit')), findsOneWidget);
      expect(find.text('Demo access: test / test'), findsOneWidget);
    });

    testWidgets('signs in with the demo credentials', (tester) async {
      AuthSession? signedIn;
      await tester
          .pumpWidget(wrap(onSignedIn: (session) => signedIn = session));

      await tester.enterText(
        find.byKey(const Key('login-username')),
        'test',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'test',
      );
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();

      expect(signedIn?.username, 'test');
    });

    testWidgets('shows an error for wrong credentials', (tester) async {
      await tester.pumpWidget(wrap(onSignedIn: (_) {}));

      await tester.enterText(
        find.byKey(const Key('login-username')),
        'test',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'wrong',
      );
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login-error')), findsOneWidget);
      expect(
        find.text('Incorrect username or password.'),
        findsOneWidget,
      );
    });

    testWidgets('validates empty fields', (tester) async {
      await tester.pumpWidget(wrap(onSignedIn: (_) {}));

      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pump();

      expect(find.text('Enter your username.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
    });

    testWidgets('hides the demo hint in remote mode', (tester) async {
      await tester.pumpWidget(
        wrap(onSignedIn: (_) {}, showDemoHint: false),
      );

      expect(find.textContaining('Demo access:'), findsNothing);
    });

    testWidgets('renders Azerbaijani', (tester) async {
      await tester.pumpWidget(
        wrap(onSignedIn: (_) {}, locale: const Locale('az')),
      );

      expect(find.text('Skanner'), findsOneWidget);
      expect(find.text('Daxil ol'), findsOneWidget);
      expect(find.text('İstifadəçi adı'), findsOneWidget);
      expect(find.text('Şifrə'), findsOneWidget);
    });

    testWidgets('renders Russian', (tester) async {
      await tester.pumpWidget(
        wrap(onSignedIn: (_) {}, locale: const Locale('ru')),
      );

      expect(find.text('Сканер'), findsOneWidget);
      expect(find.text('Войти'), findsOneWidget);
      expect(find.text('Имя пользователя'), findsOneWidget);
      expect(find.text('Пароль'), findsOneWidget);
    });
  });
}
