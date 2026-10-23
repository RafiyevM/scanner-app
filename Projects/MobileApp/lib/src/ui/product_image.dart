import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const Set<String> _knownProductIds = <String>{
  'PHN-001',
  'PHN-002',
  'PHN-003',
  'PHN-004',
  'PHN-005',
  'PHN-006',
  'PHN-007',
  'PHN-008',
  'PHN-009',
  'PHN-010',
};

String productImageAsset(String productId) {
  final String id = productId.trim().toUpperCase();
  if (_knownProductIds.contains(id)) {
    return 'assets/images/phones/$id.svg';
  }
  return 'assets/images/phones/default.svg';
}

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.productId,
    this.height = 140,
  });

  final String productId;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      productImageAsset(productId),
      height: height,
      fit: BoxFit.contain,
    );
  }
}
