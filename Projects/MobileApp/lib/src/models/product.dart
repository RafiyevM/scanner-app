class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.quantity,
    required this.barcode,
    required this.qrCode,
  });

  final String id;
  final String name;
  final String description;
  final String color;
  final int quantity;
  final String barcode;
  final String qrCode;

  bool get inStock => quantity > 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _string(json, 'id').trim(),
      name: _string(json, 'name'),
      description: _string(json, 'description'),
      color: _string(json, 'color'),
      quantity: _int(json, 'quantity'),
      barcode: _string(json, 'barcode').trim(),
      qrCode: _string(json, 'qrCode'),
    );
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String ? value : '';
  }

  static int _int(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
