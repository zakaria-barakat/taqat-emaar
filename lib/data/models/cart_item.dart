import 'product.dart';

class CartItem {
  final String id;
  final String cartId;
  final String productId;
  final int quantity;
  final DateTime? createdAt;
  final Product? product;

  const CartItem({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
    this.createdAt,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    Product? parsedProduct;
    if (json['products'] != null && json['products'] is Map<String, dynamic>) {
      parsedProduct = Product.fromJson(json['products'] as Map<String, dynamic>);
    } else if (json['product'] != null && json['product'] is Map<String, dynamic>) {
      parsedProduct = Product.fromJson(json['product'] as Map<String, dynamic>);
    }

    return CartItem(
      id: json['id'] as String,
      cartId: json['cart_id'] as String,
      productId: json['product_id'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      product: parsedProduct,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cart_id': cartId,
      'product_id': productId,
      'quantity': quantity,
    };
  }

  CartItem copyWith({
    int? quantity,
    Product? product,
  }) {
    return CartItem(
      id: id,
      cartId: cartId,
      productId: productId,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt,
      product: product ?? this.product,
    );
  }

  double get subtotal => (product?.price ?? 0.0) * quantity;
}
