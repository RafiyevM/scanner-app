import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../data/phone_identifier.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import '../services/sound_service.dart';
import '../state/scan_ui_state.dart';
import 'phone_camera.dart';
import 'result_panel.dart';

enum _Phase { starting, ready, identifying, result, cameraError }

class PhoneIdentifyView extends StatefulWidget {
  const PhoneIdentifyView({
    super.key,
    required this.identifier,
    this.cameraFactory = DevicePhoneCamera.new,
  });

  final PhoneIdentifier identifier;
  final PhoneCameraFactory cameraFactory;

  @override
  State<PhoneIdentifyView> createState() => _PhoneIdentifyViewState();
}

class _PhoneIdentifyViewState extends State<PhoneIdentifyView> {
  PhoneCamera? _camera;
  _Phase _phase = _Phase.starting;
  IdentifyResult? _result;
  Uint8List? _lastPhoto;

  @override
  void initState() {
    super.initState();
    unawaited(_openCamera());
  }

  @override
  void dispose() {
    final PhoneCamera? camera = _camera;
    _camera = null;
    if (camera != null) {
      unawaited(camera.dispose());
    }
    super.dispose();
  }

  Future<void> _openCamera() async {
    setState(() {
      _phase = _Phase.starting;
      _result = null;
    });

    final PhoneCamera camera = widget.cameraFactory();
    try {
      await camera.initialize();
    } catch (_) {
      await camera.dispose();
      if (mounted) {
        setState(() => _phase = _Phase.cameraError);
      }
      return;
    }

    if (!mounted) {
      await camera.dispose();
      return;
    }
    setState(() {
      _camera = camera;
      _phase = _Phase.ready;
    });
  }

  Future<void> _closeCamera() async {
    final PhoneCamera? camera = _camera;
    _camera = null;
    await camera?.dispose();
  }

  Future<void> _identify() async {
    final PhoneCamera? camera = _camera;
    if (camera == null || _phase != _Phase.ready) {
      return;
    }

    setState(() => _phase = _Phase.identifying);
    unawaited(SoundService.instance.playBeep());

    Uint8List photo;
    try {
      photo = await camera.takePhoto();
    } catch (_) {
      if (mounted) {
        setState(() => _phase = _Phase.ready);
      }
      return;
    }

    _lastPhoto = photo;
    await _sendPhoto(photo);
  }

  Future<void> _sendPhoto(Uint8List photo) async {
    if (mounted) {
      setState(() => _phase = _Phase.identifying);
    }
    final IdentifyResult result = await widget.identifier.identify(photo);
    if (!mounted) {
      return;
    }
    setState(() {
      _result = result;
      _phase = _Phase.result;
    });
    unawaited(_closeCamera());
  }

  Future<void> _retry() async {
    final Uint8List? photo = _lastPhoto;
    if (photo == null) {
      await _openCamera();
      return;
    }
    await _sendPhoto(photo);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Column(
      children: <Widget>[
        Expanded(child: _topArea(l10n)),
        const SizedBox(height: 14),
        _bottomArea(l10n),
      ],
    );
  }

  Widget _topArea(AppLocalizations l10n) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final Widget child = switch (_phase) {
      _Phase.starting => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      _Phase.cameraError => Center(
          child: Text(
            l10n.phoneCameraError,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      _Phase.ready || _Phase.identifying => _camera == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Positioned.fill(child: _camera!.buildPreview()),
                const Positioned.fill(child: _PhoneFrame()),
                if (_phase == _Phase.identifying)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
      _Phase.result => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.smartphone,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _resultTitle(l10n),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ColoredBox(color: const Color(0xFF111827), child: child),
      ),
    );
  }

  String _resultTitle(AppLocalizations l10n) {
    final IdentifyResult? result = _result;
    return switch (result) {
      IdentifySuccess() => l10n.identifiedAs(
          result.titleName,
          (result.confidence * 100).round(),
        ),
      IdentifyNotPhone() => l10n.notAPhone,
      _ => '',
    };
  }

  Widget _bottomArea(AppLocalizations l10n) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    Widget card(Widget child) => Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        );

    switch (_phase) {
      case _Phase.starting:
      case _Phase.cameraError:
        return card(
          _phase == _Phase.cameraError
              ? FilledButton(
                  onPressed: _openCamera,
                  child: Text(l10n.tryAgain),
                )
              : Text(l10n.phoneHint, style: theme.textTheme.bodyMedium),
        );
      case _Phase.ready:
        return card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.phoneHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('identify-button'),
                  onPressed: _identify,
                  icon: const Icon(Icons.center_focus_strong, size: 20),
                  label: Text(l10n.identifyButton),
                ),
              ),
            ],
          ),
        );
      case _Phase.identifying:
        return card(
          Row(
            children: <Widget>[
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 14),
              Text(l10n.identifying, style: theme.textTheme.bodyLarge),
            ],
          ),
        );
      case _Phase.result:
        return _resultCard(l10n, card);
    }
  }

  Widget _resultCard(
    AppLocalizations l10n,
    Widget Function(Widget child) card,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final IdentifyResult? result = _result;

    Widget again() => SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('identify-another'),
            onPressed: _openCamera,
            icon: const Icon(Icons.smartphone, size: 20),
            label: Text(l10n.identifyAnother),
          ),
        );

    Widget message(IconData icon, String title, {String? detail}) => card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: scheme.error),
              const SizedBox(height: 10),
              Text(title, style: theme.textTheme.titleMedium),
              if (detail != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              again(),
            ],
          ),
        );

    switch (result) {
      case IdentifySuccess():
        final String name = result.displayName;
        final String title = l10n.identifiedAs(
          result.titleName,
          (result.confidence * 100).round(),
        );
        if (result.matches.isEmpty) {
          final bool otherColors =
              result.modelMatches.isNotEmpty && result.color.isNotEmpty;
          return message(
            Icons.search_off,
            title,
            detail: [
              if (otherColors)
                l10n.notInDepotColor(
                  name,
                  result.color,
                  result.depotColors.join(', '),
                )
              else
                l10n.notInDepotModel(name),
              if (result.confidence < 0.5) l10n.lowConfidence,
            ].join('\n'),
          );
        }
        final Product match = result.matches.first;
        final ScanUiState state =
            match.inStock ? SuccessState(match) : OutOfStockState(match);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (result.confidence < 0.5 || result.color.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                child: Text(
                  [
                    if (result.color.isEmpty) l10n.colorNotDetected,
                    if (result.confidence < 0.5) l10n.lowConfidence,
                  ].join(' '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ),
            ResultPanel(
              state: state,
              onScanAgain: _openCamera,
              onRetry: () async {},
              scanAgainLabel: l10n.identifyAnother,
            ),
          ],
        );
      case IdentifyNotPhone():
        return message(Icons.smartphone, l10n.notAPhone);
      case IdentifyNotConfigured():
        return message(
          Icons.settings_suggest_outlined,
          l10n.recognitionNotConfigured,
        );
      case IdentifyFailure():
        return card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.cloud_off_outlined, color: scheme.error),
              const SizedBox(height: 10),
              Text(
                l10n.couldNotLoadProduct,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                _failureText(l10n, result.type),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('identify-retry'),
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: Text(l10n.tryAgain),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _openCamera,
                      child: Text(l10n.identifyAnother),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case null:
        return const SizedBox.shrink();
    }
  }

  String _failureText(AppLocalizations l10n, LookupFailureType type) {
    return switch (type) {
      LookupFailureType.unauthorized => l10n.lookupUnauthorized,
      LookupFailureType.serverUnavailable => l10n.lookupServerUnavailable,
      LookupFailureType.requestFailed => l10n.lookupRequestFailed(0),
      LookupFailureType.unreachable => l10n.lookupUnreachable,
      LookupFailureType.unexpectedResponse => l10n.lookupUnexpected,
      LookupFailureType.timeout => l10n.lookupTimeout,
      LookupFailureType.localData => l10n.lookupLocalData,
    };
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.maxHeight * 0.78;
        final double width = height * 0.52;
        return Center(
          child: Container(
            width: width.clamp(0, constraints.maxWidth * 0.8),
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 2.5,
              ),
            ),
          ),
        );
      },
    );
  }
}
