import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'l10n/app_localizations.dart';
import 'src/auth/auth_repository.dart';
import 'src/auth/auth_session.dart';
import 'src/auth/local_auth_repository.dart';
import 'src/auth/remote_auth_repository.dart';
import 'src/data/local_product_repository.dart';
import 'src/data/phone_identifier.dart';
import 'src/data/product_registrar.dart';
import 'src/data/product_repository.dart';
import 'src/data/product_store.dart';
import 'src/data/remote_product_repository.dart';
import 'src/services/sound_service.dart';
import 'src/state/scanner_view_model.dart';
import 'src/ui/home_screen.dart';
import 'src/ui/login_screen.dart';
import 'src/ui/scanner_screen.dart';
import 'src/ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QrScannerApp());
  unawaited(SoundService.instance.preload());
}

class AppConfig {
  // "local" reads assets/products.json.
  // "remote" calls the ProductApi, which reads PostgreSQL.
  static const String dataSource = 'remote';

  // Must end with "/". Override at build time:
  //   flutter build apk --dart-define=API_BASE_URL=https://your-host/
  // Defaults to the public HTTPS tunnel, so the app works without a USB cable.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://walnut-maternity-mature-gardening.trycloudflare.com/',
  );

  // "local" uses the demo credential gate below.
  // "remote" calls the provisional POST {baseUrl}auth/login contract.
  static const String authMode = 'local';
  static const String demoUsername = 'test';
  static const String demoPassword = 'test';
}

class QrScannerApp extends StatefulWidget {
  const QrScannerApp({super.key});

  @override
  State<QrScannerApp> createState() => _QrScannerAppState();
}

class _QrScannerAppState extends State<QrScannerApp> {
  late final ProductRepository _repository;
  late final AuthRepository _authRepository;
  late final ScannerViewModel _viewModel;

  AuthSession? _session;
  bool _showScanner = false;
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _repository = _createRepository();
    _authRepository = _createAuthRepository();
    _viewModel = ScannerViewModel(_repository);
  }

  AuthRepository _createAuthRepository() {
    if (AppConfig.authMode == 'remote') {
      return RemoteAuthRepository(
        baseUrl: AppConfig.apiBaseUrl,
        client: http.Client(),
      );
    }
    return const LocalAuthRepository(
      username: AppConfig.demoUsername,
      password: AppConfig.demoPassword,
    );
  }

  ProductRepository _createRepository() {
    if (AppConfig.dataSource == 'remote') {
      return RemoteProductRepository(
        baseUrl: AppConfig.apiBaseUrl,
        client: http.Client(),
      );
    }
    return LocalProductRepository(const AssetProductStore());
  }

  void _signIn(AuthSession session) {
    setState(() {
      _session = session;
      _showScanner = false;
    });
  }

  void _signOut() {
    setState(() {
      _session = null;
      _showScanner = false;
    });
    _viewModel.reset();
  }

  void _openScanner() {
    setState(() => _showScanner = true);
  }

  void _closeScanner() {
    setState(() => _showScanner = false);
    _viewModel.reset();
  }

  void _changeLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    final ProductRepository repository = _repository;
    if (repository is RemoteProductRepository) {
      repository.dispose();
    }
    final AuthRepository authRepository = _authRepository;
    if (authRepository is RemoteAuthRepository) {
      authRepository.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_session == null) {
      return LoginScreen(
        authRepository: _authRepository,
        locale: _locale,
        onLocaleChanged: _changeLocale,
        showDemoHint: AppConfig.authMode == 'local',
        demoUsername: AppConfig.demoUsername,
        demoPassword: AppConfig.demoPassword,
        onSignedIn: _signIn,
      );
    }

    if (_showScanner) {
      return ScannerScreen(
        viewModel: _viewModel,
        username: _session!.username,
        locale: _locale,
        onLocaleChanged: _changeLocale,
        onBack: _closeScanner,
        registrar: _repository is ProductRegistrar
            ? _repository as ProductRegistrar
            : null,
        identifier: _repository is PhoneIdentifier
            ? _repository as PhoneIdentifier
            : null,
      );
    }

    return HomeScreen(
      username: _session!.username,
      locale: _locale,
      onLocaleChanged: _changeLocale,
      onScan: _openScanner,
      onLogout: _signOut,
    );
  }
}
