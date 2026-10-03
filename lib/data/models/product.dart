import 'product_image.dart';
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int stockQuantity;
  final String categoryId;
  final List<ProductImage> images;
  final String sellingUnit;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.stockQuantity,
    required this.categoryId,
    required this.images,
    required this.sellingUnit,
    this.isActive = true,
  });
}