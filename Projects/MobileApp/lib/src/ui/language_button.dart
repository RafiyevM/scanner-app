import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class LanguageButton extends StatelessWidget {
  const LanguageButton({
    super.key,
    required this.locale,
    required this.onChanged,
    this.color,
  });

  final Locale locale;
  final ValueChanged<Locale> onChanged;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return PopupMenuButton<Locale>(
      tooltip: l10n.language,
      icon: Icon(Icons.translate, color: color),
      onSelected: onChanged,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
        CheckedPopupMenuItem<Locale>(
          value: const Locale('en'),
          checked: locale.languageCode == 'en',
          child: Text(l10n.languageEnglish),
        ),
        CheckedPopupMenuItem<Locale>(
          value: const Locale('az'),
          checked: locale.languageCode == 'az',
          child: Text(l10n.languageAzerbaijani),
        ),
        CheckedPopupMenuItem<Locale>(
          value: const Locale('ru'),
          checked: locale.languageCode == 'ru',
          child: Text(l10n.languageRussian),
        ),
      ],
    );
  }
}
