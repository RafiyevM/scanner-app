import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'language_button.dart';
import 'product_image.dart';
import 'sound_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.username,
    required this.locale,
    required this.onLocaleChanged,
    required this.onScan,
    required this.onLogout,
  });

  final String username;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final VoidCallback onScan;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: <Widget>[
          LanguageButton(locale: locale, onChanged: onLocaleChanged),
          const SoundButton(),
          IconButton(
            tooltip: l10n.signOut,
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 4),
        ],
      ),
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Card(
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
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Container(
                              height: 190,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: <Color>[
                                    scheme.primaryContainer.withValues(
                                      alpha: 0.7,
                                    ),
                                    scheme.tertiaryContainer.withValues(
                                      alpha: 0.35,
                                    ),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: ProductImage(
                                  productId: 'PHN-001',
                                  height: 180,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              l10n.welcome(username),
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.homePrompt,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 22),
                            FilledButton.icon(
                              onPressed: onScan,
                              icon: const Icon(Icons.qr_code_scanner, size: 22),
                              label: Text(l10n.scanButton),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
