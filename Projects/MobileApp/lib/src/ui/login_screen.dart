import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_session.dart';
import '../state/login_view_model.dart';
import 'language_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authRepository,
    required this.onSignedIn,
    required this.locale,
    required this.onLocaleChanged,
    this.showDemoHint = false,
    this.demoUsername = '',
    this.demoPassword = '',
  });

  final AuthRepository authRepository;
  final ValueChanged<AuthSession> onSignedIn;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final bool showDemoHint;
  final String demoUsername;
  final String demoPassword;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final LoginViewModel _viewModel;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel(widget.authRepository);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    FocusScope.of(context).unfocus();
    final bool signedIn = await _viewModel.signIn(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted || !signedIn) {
      return;
    }

    final AuthSession? session = _viewModel.session;
    if (session != null) {
      widget.onSignedIn(session);
    }
  }

  String _errorText(AppLocalizations l10n, AuthFailureType type) {
    return switch (type) {
      AuthFailureType.missingFields => l10n.authMissingFields,
      AuthFailureType.invalidCredentials => l10n.authInvalidCredentials,
      AuthFailureType.failed => l10n.authFailed,
      AuthFailureType.timedOut => l10n.authTimedOut,
      AuthFailureType.unreachable => l10n.authUnreachable,
      AuthFailureType.unexpectedResponse => l10n.authUnexpected,
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool dark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const <Color>[Color(0xFF081326), Color(0xFF102A43)]
                : const <Color>[Color(0xFFF4F7FF), Color(0xFFE6EFFF)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -120,
              right: -80,
              child: _GlowCircle(color: scheme.primary, size: 320),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: _GlowCircle(color: scheme.tertiary, size: 340),
            ),
            Positioned(
              top: 0,
              right: 4,
              child: SafeArea(
                child: LanguageButton(
                  locale: widget.locale,
                  onChanged: widget.onLocaleChanged,
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      color: scheme.surface.withValues(alpha: 0.94),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: ListenableBuilder(
                          listenable: _viewModel,
                          builder: (BuildContext context, Widget? child) {
                            final LoginUiState state = _viewModel.state;
                            final bool loading = state is LoginLoading;

                            return AutofillGroup(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Center(
                                      child: Container(
                                        width: 76,
                                        height: 76,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: <Color>[
                                              scheme.primary,
                                              scheme.tertiary,
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          boxShadow: <BoxShadow>[
                                            BoxShadow(
                                              color: scheme.primary.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 22,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.qr_code_scanner,
                                          size: 40,
                                          color: scheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      l10n.appName,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.loginSubtitle,
                                      textAlign: TextAlign.center,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    TextFormField(
                                      key: const Key('login-username'),
                                      controller: _usernameController,
                                      enabled: !loading,
                                      textInputAction: TextInputAction.next,
                                      textCapitalization:
                                          TextCapitalization.none,
                                      autocorrect: false,
                                      autofillHints: const <String>[
                                        AutofillHints.username,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: l10n.username,
                                        prefixIcon:
                                            const Icon(Icons.person_outline),
                                      ),
                                      validator: (String? value) =>
                                          value == null || value.trim().isEmpty
                                              ? l10n.usernameRequired
                                              : null,
                                      onChanged: (_) => _viewModel.clearError(),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      key: const Key('login-password'),
                                      controller: _passwordController,
                                      enabled: !loading,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      autofillHints: const <String>[
                                        AutofillHints.password,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: l10n.password,
                                        prefixIcon:
                                            const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          tooltip: _obscurePassword
                                              ? l10n.showPassword
                                              : l10n.hidePassword,
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                          onPressed: loading
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _obscurePassword =
                                                        !_obscurePassword;
                                                  });
                                                },
                                        ),
                                      ),
                                      validator: (String? value) =>
                                          value == null || value.isEmpty
                                              ? l10n.passwordRequired
                                              : null,
                                      onChanged: (_) => _viewModel.clearError(),
                                      onFieldSubmitted: (_) => _submit(),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: state is LoginError
                                          ? Container(
                                              key: ValueKey<AuthFailureType>(
                                                state.type,
                                              ),
                                              margin: const EdgeInsets.only(
                                                top: 14,
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: scheme.errorContainer,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Icon(
                                                    Icons.error_outline,
                                                    size: 20,
                                                    color:
                                                        scheme.onErrorContainer,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      _errorText(
                                                        l10n,
                                                        state.type,
                                                      ),
                                                      key: const Key(
                                                        'login-error',
                                                      ),
                                                      style: theme
                                                          .textTheme.bodyMedium
                                                          ?.copyWith(
                                                        color: scheme
                                                            .onErrorContainer,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    const SizedBox(height: 24),
                                    FilledButton(
                                      key: const Key('login-submit'),
                                      onPressed: loading ? null : _submit,
                                      child: loading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                const Icon(
                                                  Icons.login,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(l10n.signIn),
                                              ],
                                            ),
                                    ),
                                    if (widget.showDemoHint) ...<Widget>[
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: scheme.surfaceContainerHighest
                                              .withValues(alpha: 0.7),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Icon(
                                              Icons.info_outline,
                                              size: 18,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                l10n.demoAccess(
                                                  widget.demoUsername,
                                                  widget.demoPassword,
                                                ),
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 18),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(
                                          Icons.lock_outline,
                                          size: 14,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            l10n.cameraAfterSignIn,
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
