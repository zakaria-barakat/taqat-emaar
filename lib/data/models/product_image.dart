class ProductImage {
  final String id;
  final String url;
  final int sortOrder;
  final String? productId;

  const ProductImage({
    required this.id,
    required this.url,
    required this.sortOrder,
    this.productId,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as String,
      url: json['url'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      productId: json['product_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'sort_order': sortOrder,
      if (productId != null) 'product_id': productId,
    };
  }
}