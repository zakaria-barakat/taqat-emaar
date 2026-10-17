import '../models/cart_item.dart';
import '../services/cart_service.dart';

class CartRepository {
  final CartService cartService;

  CartRepository(this.cartService);

  Future<String> getOrCreateCartId(String userId) {
    return cartService.getOrCreateCartId(userId);
  }

  Future<List<CartItem>> getCartItems(String cartId) {
    return cartService.getCartItems(cartId);
  }

  Future<void> addItem({
    required String cartId,
    required String productId,
    required int quantity,
  }) {
    return cartService.addItem(
      cartId: cartId,
      productId: productId,
      quantity: quantity,
    );
  }

  Future<void> updateQuantity({
    required String cartItemId,
    required int newQuantity,
  }) {
    return cartService.updateQuantity(
      cartItemId: cartItemId,
      newQuantity: newQuantity,
    );
  }

  Future<void> removeItem(String cartItemId) {
    return cartService.removeItem(cartItemId);
  }

  Future<void> clearCart(String cartId) {
    return cartService.clearCart(cartId);
  }
}
