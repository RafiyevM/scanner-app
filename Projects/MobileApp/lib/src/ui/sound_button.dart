import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../services/sound_service.dart';

class SoundButton extends StatelessWidget {
  const SoundButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: SoundService.instance.enabled,
      builder: (BuildContext context, bool enabled, Widget? child) {
        return IconButton(
          tooltip: enabled ? l10n.soundOn : l10n.soundOff,
          onPressed: () {
            SoundService.instance.enabled.value = !enabled;
          },
          icon: Icon(
            enabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
            color: color,
          ),
        );
      },
    );
  }
}
