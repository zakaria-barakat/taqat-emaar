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
    this.images = const [],
    required this.sellingUnit,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['product_images'] ?? json['images'];
    final List<ProductImage> parsedImages;
    if (rawImages is List) {
      parsedImages = rawImages
          .map((item) => ProductImage.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      parsedImages = const [];
    }

    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'YER',
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      categoryId: json['category_id'] as String,
      images: parsedImages,
      sellingUnit: json['selling_unit'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'stock_quantity': stockQuantity,
      'category_id': categoryId,
      'selling_unit': sellingUnit,
      'is_active': isActive,
      'product_images': images.map((img) => img.toJson()).toList(),
    };
  }
}