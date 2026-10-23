import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/app_localizations.dart';
import '../data/phone_identifier.dart';
import '../data/product_registrar.dart';
import '../models/product.dart';
import '../services/sound_service.dart';
import '../state/scan_ui_state.dart';
import '../state/scanner_view_model.dart';
import 'add_product_sheet.dart';
import 'language_button.dart';
import 'phone_camera.dart';
import 'phone_identify_view.dart';
import 'result_panel.dart';
import 'sound_button.dart';

enum ScanMode { qr, barcode, phone }

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    super.key,
    required this.viewModel,
    required this.username,
    required this.locale,
    required this.onLocaleChanged,
    required this.onBack,
    this.registrar,
    this.identifier,
    this.phoneCameraFactory = DevicePhoneCamera.new,
  });

  final ScannerViewModel viewModel;
  final String username;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final VoidCallback onBack;
  final ProductRegistrar? registrar;
  final PhoneIdentifier? identifier;
  final PhoneCameraFactory phoneCameraFactory;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  late MobileScannerController _controller;
  PermissionStatus? _permissionStatus;
  bool _checkingPermission = true;
  bool _startingCamera = false;
  bool _resultReached = false;
  ScanMode _mode = ScanMode.qr;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = _createController();
    widget.viewModel.addListener(_handleStateChange);
    _ensurePermission();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_handleStateChange);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensurePermission();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopCamera();
    }
  }

  MobileScannerController _createController() {
    return MobileScannerController(
      formats: _formatsFor(_mode),
      detectionSpeed: DetectionSpeed.noDuplicates,
      autoStart: false,
    );
  }

  List<BarcodeFormat> _formatsFor(ScanMode mode) {
    if (mode == ScanMode.qr || mode == ScanMode.phone) {
      return const <BarcodeFormat>[BarcodeFormat.qrCode];
    }
    return const <BarcodeFormat>[
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.itf,
      BarcodeFormat.codabar,
    ];
  }

  Future<void> _switchMode(ScanMode mode) async {
    if (mode == _mode || _resultReached) {
      return;
    }

    final MobileScannerController previous = _controller;
    final bool leavingPhone = _mode == ScanMode.phone;

    if (mode == ScanMode.phone) {
      try {
        await previous.stop();
      } catch (_) {
        // The previous controller may not have started.
      }
      if (!mounted) {
        return;
      }
    }

    setState(() {
      _mode = mode;
      _controller = _createController();
    });
    widget.viewModel.reset();

    await Future<void>.delayed(
      leavingPhone ? const Duration(milliseconds: 350) : Duration.zero,
    );
    try {
      await previous.stop();
    } catch (_) {
      // The previous controller may not have started.
    }
    await previous.dispose();

    if (!mounted) {
      return;
    }
    if (_permissionStatus?.isGranted ?? false) {
      await _startCamera();
    }
  }

  Future<void> _ensurePermission() async {
    if (_resultReached) {
      if (mounted) {
        setState(() => _checkingPermission = false);
      }
      return;
    }

    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _permissionStatus = status;
      _checkingPermission = false;
    });
    if (status.isGranted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startCamera();
      });
    }
  }

  Future<void> _startCamera() async {
    if (_startingCamera || _resultReached || _mode == ScanMode.phone) {
      return;
    }
    _startingCamera = true;
    try {
      await _controller.start();
    } catch (_) {
      // The camera error panel is rendered by MobileScanner.errorBuilder.
    } finally {
      _startingCamera = false;
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _controller.stop();
    } catch (_) {
      // Ignore stop errors during lifecycle transitions.
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_resultReached || capture.barcodes.isEmpty) {
      return;
    }
    final String? raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) {
      return;
    }
    unawaited(SoundService.instance.playBeep());
    widget.viewModel.onQrDetected(raw);
  }

  void _handleStateChange() {
    final ScanUiState state = widget.viewModel.state;
    final bool terminal = state is SuccessState ||
        state is OutOfStockState ||
        state is NotFoundState ||
        state is InvalidState ||
        state is ErrorState;

    if (terminal && !_resultReached) {
      _resultReached = true;
      unawaited(_stopCamera());
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _addToDepot(String code) async {
    final ProductRegistrar? registrar = widget.registrar;
    if (registrar == null) {
      return;
    }
    final Product? product = await showAddProductSheet(
      context,
      code: code,
      registrar: registrar,
    );
    if (product != null && mounted) {
      widget.viewModel.showRegistered(product);
    }
  }

  Future<void> _scanAnother() async {
    final MobileScannerController previous = _controller;
    widget.viewModel.reset();
    setState(() {
      _resultReached = false;
      _controller = _createController();
    });

    await Future<void>.delayed(Duration.zero);
    try {
      await previous.stop();
    } catch (_) {
      // The previous controller was already stopped after the result.
    }
    await previous.dispose();

    if (!mounted) {
      return;
    }
    if (_permissionStatus?.isGranted ?? false) {
      await _startCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(l10n.appName),
        actions: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(widget.username, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          LanguageButton(
            locale: widget.locale,
            onChanged: widget.onLocaleChanged,
          ),
          const SoundButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: SegmentedButton<ScanMode>(
                  segments: <ButtonSegment<ScanMode>>[
                    ButtonSegment<ScanMode>(
                      value: ScanMode.qr,
                      label: Text(l10n.modeQr),
                      icon: const Icon(Icons.qr_code),
                    ),
                    ButtonSegment<ScanMode>(
                      value: ScanMode.barcode,
                      label: Text(l10n.modeBarcode),
                      icon: const Icon(Icons.view_week_outlined),
                    ),
                    if (widget.identifier != null)
                      ButtonSegment<ScanMode>(
                        value: ScanMode.phone,
                        label: Text(l10n.modePhone),
                        icon: const Icon(Icons.smartphone),
                      ),
                  ],
                  selected: <ScanMode>{_mode},
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  style: ButtonStyle(
                    side: const WidgetStatePropertyAll<BorderSide>(
                      BorderSide.none,
                    ),
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        return states.contains(WidgetState.selected)
                            ? scheme.primary
                            : Colors.transparent;
                      },
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        return states.contains(WidgetState.selected)
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant;
                      },
                    ),
                    shape: WidgetStatePropertyAll<OutlinedBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  onSelectionChanged: _resultReached
                      ? null
                      : (Set<ScanMode> selection) {
                          _switchMode(selection.first);
                        },
                ),
              ),
              const SizedBox(height: 12),
              if (_mode == ScanMode.phone &&
                  widget.identifier != null &&
                  (_permissionStatus?.isGranted ?? false))
                Expanded(
                  child: PhoneIdentifyView(
                    key: const Key('phone-identify-view'),
                    identifier: widget.identifier!,
                    cameraFactory: widget.phoneCameraFactory,
                  ),
                )
              else ...<Widget>[
                Expanded(child: _buildCameraArea(l10n)),
                const SizedBox(height: 14),
                ListenableBuilder(
                  listenable: widget.viewModel,
                  builder: (BuildContext context, Widget? child) {
                    final ScanUiState state = widget.viewModel.state;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: ResultPanel(
                        key: ValueKey<Type>(state.runtimeType),
                        state: state,
                        onScanAgain: _scanAnother,
                        onAddToDepot:
                            widget.registrar == null ? null : _addToDepot,
                        onRetry: widget.viewModel.retry,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraArea(AppLocalizations l10n) {
    if (_resultReached) {
      return _ScanCompletePanel(message: l10n.scanComplete);
    }

    if (_checkingPermission) {
      return const Center(child: CircularProgressIndicator());
    }

    final PermissionStatus? status = _permissionStatus;
    if (status == null || !status.isGranted) {
      return _PermissionPanel(
        permanentlyDenied: status?.isPermanentlyDenied ?? false,
        onRequest: _ensurePermission,
        onOpenSettings: () async {
          await openAppSettings();
        },
      );
    }

    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: MobileScanner(
                  key: ValueKey<ScanMode>(_mode),
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (
                    BuildContext context,
                    MobileScannerException error,
                    Widget? child,
                  ) {
                    return _CameraErrorPanel(
                      message: l10n.cameraUnavailableMessage,
                      onRetry: _startCamera,
                    );
                  },
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                      stops: const <double>[0, 0.22, 0.78, 1],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: _ScanOverlay(
                  mode: _mode,
                  hint: _mode == ScanMode.qr ? l10n.hintQr : l10n.hintBarcode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanOverlay extends StatefulWidget {
  const _ScanOverlay({required this.mode, required this.hint});

  final ScanMode mode;
  final String hint;

  @override
  State<_ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<_ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool barcode = widget.mode == ScanMode.barcode;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double barcodeWidth =
            (constraints.maxWidth * 0.85).clamp(240.0, 340.0).toDouble();
        final double frameWidth = barcode ? barcodeWidth : 240;
        final double frameHeight = barcode ? 110 : 240;

        return AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double t = Curves.easeInOut.transform(_controller.value);

            return Stack(
              children: <Widget>[
                Center(
                  child: SizedBox(
                    width: frameWidth,
                    height: frameHeight,
                    child: Stack(
                      children: <Widget>[
                        const Positioned.fill(
                          child: CustomPaint(
                            painter: _ScanFramePainter(
                              color: Colors.white,
                              radius: 16,
                            ),
                          ),
                        ),
                        if (barcode)
                          Center(
                            child: Container(
                              width: frameWidth - 40,
                              height: 2,
                              color: Colors.redAccent.withValues(alpha: 0.9),
                            ),
                          ),
                        if (!barcode)
                          Positioned(
                            left: 18,
                            right: 18,
                            top: 14 + t * (frameHeight - 28),
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white,
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Positioned(
                            top: 14,
                            bottom: 14,
                            left: 18 + t * (frameWidth - 36),
                            child: Container(
                              width: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: 0.8),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            barcode ? Icons.view_week_outlined : Icons.qr_code,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.hint,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: 0.35),
    );

    final Paint corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;
    const double length = 26;

    canvas.drawLine(const Offset(0, 2), const Offset(length, 2), corner);
    canvas.drawLine(const Offset(2, 0), const Offset(2, length), corner);

    canvas.drawLine(
      Offset(size.width - length, 2),
      Offset(size.width, 2),
      corner,
    );
    canvas.drawLine(
      Offset(size.width - 2, 0),
      Offset(size.width - 2, length),
      corner,
    );

    canvas.drawLine(
      Offset(0, size.height - 2),
      Offset(length, size.height - 2),
      corner,
    );
    canvas.drawLine(
      Offset(2, size.height - length),
      Offset(2, size.height),
      corner,
    );

    canvas.drawLine(
      Offset(size.width - length, size.height - 2),
      Offset(size.width, size.height - 2),
      corner,
    );
    canvas.drawLine(
      Offset(size.width - 2, size.height - length),
      Offset(size.width - 2, size.height),
      corner,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _ScanCompletePanel extends StatelessWidget {
  const _ScanCompletePanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Center(
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
                Icons.check_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionPanel extends StatelessWidget {
  const _PermissionPanel({
    required this.permanentlyDenied,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final bool permanentlyDenied;
  final Future<void> Function() onRequest;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.permissionTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                permanentlyDenied
                    ? l10n.permissionDenied
                    : l10n.permissionRationale,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (!permanentlyDenied) ...<Widget>[
                FilledButton(
                  onPressed: () {
                    onRequest();
                  },
                  child: Text(l10n.allowCamera),
                ),
                const SizedBox(height: 4),
              ],
              TextButton(
                onPressed: () {
                  onOpenSettings();
                },
                child: Text(
                  l10n.openSettings,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraErrorPanel extends StatelessWidget {
  const _CameraErrorPanel({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.cameraUnavailable,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  onRetry();
                },
                child: Text(l10n.retryCamera),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
