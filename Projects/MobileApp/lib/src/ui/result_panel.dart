import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import '../state/scan_ui_state.dart';
import 'product_image.dart';

class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.state,
    required this.onScanAgain,
    required this.onRetry,
    this.onAddToDepot,
    this.scanAgainLabel,
  });

  final ScanUiState state;
  final VoidCallback onScanAgain;
  final Future<void> Function() onRetry;
  final void Function(String code)? onAddToDepot;
  final String? scanAgainLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: switch (state) {
            ScanningState() => _scanning(context),
            LoadingState(:final String code) => _loading(context, code),
            SuccessState(:final Product product) => _product(
                context,
                product,
                inStock: true,
              ),
            OutOfStockState(:final Product product) => _product(
                context,
                product,
                inStock: false,
              ),
            NotFoundState(:final String code) => _notFound(context, code),
            InvalidState(:final String reason) => _invalid(context, reason),
            ErrorState(
              :final LookupFailureType failureType,
              :final bool retryable,
              :final int? statusCode,
            ) =>
              _error(context, failureType, retryable, statusCode),
          },
        ),
      ),
    );
  }

  Widget _scanning(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _IconBubble(
          icon: Icons.qr_code_scanner,
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.readyTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                l10n.readyHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _loading(BuildContext context, String code) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            l10n.lookingUp(code),
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _product(
    BuildContext context,
    Product product, {
    required bool inStock,
  }) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String stock =
        inStock ? l10n.quantityInStock(product.quantity) : l10n.outOfStock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _statusHeader(context, inStock: inStock),
        const SizedBox(height: 14),
        Center(
          child: Container(
            height: 138,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: ProductImage(productId: product.id, height: 122),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          product.name.isEmpty ? product.id : product.name,
          style: theme.textTheme.headlineSmall,
        ),
        if (product.description.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            product.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double half = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _InfoTile(
                  width: half,
                  icon: Icons.tag,
                  label: l10n.idLabel,
                  value: product.id,
                ),
                _InfoTile(
                  width: half,
                  icon: Icons.palette_outlined,
                  label: l10n.colorLabel,
                  value: product.color.isEmpty ? '—' : product.color,
                ),
                _InfoTile(
                  width: half,
                  icon: Icons.inventory_2_outlined,
                  label: l10n.stockLabel,
                  value: stock,
                ),
                _InfoTile(
                  width: half,
                  icon: Icons.qr_code_2,
                  label: l10n.barcodeLabel,
                  value: product.barcode.isEmpty ? '—' : product.barcode,
                  fitOneLine: true,
                ),
              ],
            );
          },
        ),
        if (!inStock) ...<Widget>[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.notAvailableDepot,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onScanAgain,
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            label: Text(scanAgainLabel ?? l10n.scanAnotherCode),
          ),
        ),
      ],
    );
  }

  Widget _statusHeader(BuildContext context, {required bool inStock}) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color background =
        inStock ? scheme.primaryContainer : scheme.errorContainer;
    final Color foreground =
        inStock ? scheme.onPrimaryContainer : scheme.onErrorContainer;

    return Row(
      children: <Widget>[
        _IconBubble(
          icon: inStock
              ? Icons.check_circle_outline
              : Icons.remove_shopping_cart_outlined,
          background: background,
          foreground: foreground,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            inStock ? l10n.productFound : l10n.notInStock,
            style: theme.textTheme.titleMedium,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            inStock ? l10n.inStock : l10n.unavailable,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _notFound(BuildContext context, String code) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _IconBubble(
          icon: Icons.search_off,
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
        ),
        const SizedBox(height: 12),
        Text(l10n.noSuchProduct, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          l10n.noProductMatches(code),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        if (onAddToDepot != null) ...<Widget>[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('add-to-depot'),
              onPressed: () => onAddToDepot!(code),
              icon: const Icon(Icons.add_box_outlined, size: 20),
              label: Text(l10n.addToDepot),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onScanAgain,
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: Text(l10n.scanAnotherCode),
            ),
          ),
        ] else
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onScanAgain,
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: Text(l10n.scanAnotherCode),
            ),
          ),
      ],
    );
  }

  Widget _invalid(BuildContext context, String reason) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _IconBubble(
          icon: Icons.error_outline,
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
        ),
        const SizedBox(height: 12),
        Text(l10n.unsupportedCode, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          reason,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.invalidHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onScanAgain,
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            label: Text(l10n.scanAnotherCode),
          ),
        ),
      ],
    );
  }

  Widget _error(
    BuildContext context,
    LookupFailureType failureType,
    bool retryable,
    int? statusCode,
  ) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _IconBubble(
          icon: Icons.cloud_off_outlined,
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.couldNotLoadProduct,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          _failureMessage(l10n, failureType, statusCode),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            if (retryable) ...<Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    onRetry();
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                  label: Text(l10n.tryAgain),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: FilledButton(
                onPressed: onScanAgain,
                child: Text(l10n.scanAnotherCode),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _failureMessage(
    AppLocalizations l10n,
    LookupFailureType type,
    int? statusCode,
  ) {
    return switch (type) {
      LookupFailureType.unauthorized => l10n.lookupUnauthorized,
      LookupFailureType.serverUnavailable => l10n.lookupServerUnavailable,
      LookupFailureType.requestFailed =>
        l10n.lookupRequestFailed(statusCode ?? 0),
      LookupFailureType.unreachable => l10n.lookupUnreachable,
      LookupFailureType.unexpectedResponse => l10n.lookupUnexpected,
      LookupFailureType.timeout => l10n.lookupTimeout,
      LookupFailureType.localData => l10n.lookupLocalData,
    };
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 22, color: foreground),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.fitOneLine = false,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final bool fitOneLine;

  Widget _value(ThemeData theme) {
    final TextStyle? style = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    if (!fitOneLine) {
      return Text(value, style: style);
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(value, style: style, maxLines: 1, softWrap: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                _value(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
