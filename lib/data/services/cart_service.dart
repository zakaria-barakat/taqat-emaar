import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';

class CartService {
  final SupabaseClient client;

  CartService(this.client);

  static const String _cartItemSelect = '''
    id,
    cart_id,
    product_id,
    quantity,
    created_at,
    products (
      id,
      name,
      description,
      price,
      currency,
      stock_quantity,
      category_id,
      selling_unit,
      is_active,
      product_images (
        id,
        product_id,
        url,
        sort_order
      )
    )
  ''';

  Future<String> getOrCreateCartId(String userId) async {
    final existingCart = await client
        .from('carts')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (existingCart != null) {
      return existingCart['id'] as String;
    }

    final newCart = await client
        .from('carts')
        .insert({'user_id': userId})
        .select('id')
        .single();

    return newCart['id'] as String;
  }

  Future<List<CartItem>> getCartItems(String cartId) async {
    final response = await client
        .from('cart_items')
        .select(_cartItemSelect)
        .eq('cart_id', cartId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => CartItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> addItem({
    required String cartId,
    required String productId,
    required int quantity,
  }) async {
    final existingItem = await client
        .from('cart_items')
        .select('id, quantity')
        .eq('cart_id', cartId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existingItem != null) {
      final currentQty = (existingItem['quantity'] as num).toInt();
      final newQty = currentQty + quantity;
      await client
          .from('cart_items')
          .update({'quantity': newQty, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', existingItem['id']);
    } else {
      await client.from('cart_items').insert({
        'cart_id': cartId,
        'product_id': productId,
        'quantity': quantity,
      });
    }
  }

  Future<void> updateQuantity({
    required String cartItemId,
    required int newQuantity,
  }) async {
    if (newQuantity <= 0) {
      await removeItem(cartItemId);
    } else {
      await client.from('cart_items').update({
        'quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', cartItemId);
    }
  }

  Future<void> removeItem(String cartItemId) async {
    await client.from('cart_items').delete().eq('id', cartItemId);
  }

  Future<void> clearCart(String cartId) async {
    await client.from('cart_items').delete().eq('cart_id', cartId);
  }
}
