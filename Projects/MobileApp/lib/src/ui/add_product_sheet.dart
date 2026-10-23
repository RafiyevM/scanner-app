import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../data/product_registrar.dart';
import '../models/product.dart';

Future<Product?> showAddProductSheet(
  BuildContext context, {
  required String code,
  required ProductRegistrar registrar,
}) {
  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) =>
        AddProductSheet(code: code, registrar: registrar),
  );
}

class AddProductSheet extends StatefulWidget {
  const AddProductSheet({
    super.key,
    required this.code,
    required this.registrar,
  });

  final String code;
  final ProductRegistrar registrar;

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _color = TextEditingController();
  int _quantity = 1;
  bool _saving = false;
  String? _nameError;
  String? _saveError;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _color.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l10n.nameRequired);
      return;
    }

    setState(() {
      _saving = true;
      _nameError = null;
      _saveError = null;
    });

    final RegisterResult result = await widget.registrar.register(
      NewProduct(
        code: widget.code,
        name: name,
        description: _description.text.trim(),
        color: _color.text.trim(),
        quantity: _quantity,
      ),
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case RegisterSuccess(:final Product product):
        Navigator.of(context).pop(product);
      case RegisterDuplicate():
        setState(() {
          _saving = false;
          _saveError = l10n.registerDuplicate;
        });
      case RegisterFailure():
        setState(() {
          _saving = false;
          _saveError = l10n.registerFailed;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.addProductTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.qr_code_2,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.addProductCode,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.code,
                            maxLines: 1,
                            softWrap: false,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('add-product-name'),
              controller: _name,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: l10n.productNameLabel,
                errorText: _nameError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('add-product-description'),
              controller: _description,
              enabled: !_saving,
              maxLength: 500,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.productDescriptionLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('add-product-color'),
              controller: _color,
              enabled: !_saving,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: l10n.productColorLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.productQuantityLabel,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                IconButton.filledTonal(
                  key: const Key('add-product-minus'),
                  onPressed: _saving || _quantity <= 0
                      ? null
                      : () => setState(() => _quantity--),
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton.filledTonal(
                  key: const Key('add-product-plus'),
                  onPressed: _saving || _quantity >= 100000
                      ? null
                      : () => setState(() => _quantity++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (_saveError != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                _saveError!,
                key: const Key('add-product-error'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancelAction),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const Key('add-product-save'),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.saveProduct),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
