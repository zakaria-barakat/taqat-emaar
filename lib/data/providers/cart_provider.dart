import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';
import '../repositories/cart_repository.dart';
import '../services/cart_service.dart';
import 'auth_provider.dart';

class CartState {
  final String? cartId;
  final List<CartItem> items;
  final bool isLoading;
  final String? errorMessage;

  const CartState({
    this.cartId,
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CartState copyWith({
    String? cartId,
    List<CartItem>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CartState(
      cartId: cartId ?? this.cartId,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  bool get hasCurrencyMismatch {
    if (items.isEmpty) return false;
    final firstCurrency = items.first.product?.currency ?? 'YER';
    return items.any((item) => (item.product?.currency ?? 'YER') != firstCurrency);
  }

  String get currency {
    if (items.isEmpty) return 'YER';
    return items.first.product?.currency ?? 'YER';
  }

  double get totalAmount {
    if (hasCurrencyMismatch) return 0.0;
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }
}

class CartNotifier extends Notifier<CartState> {
  CartRepository get _repository => ref.read(cartRepositoryProvider);

  @override
  CartState build() {
    ref.listen(currentUserProvider, (previous, next) {
      if (previous?.id != next?.id) {
        loadCart();
      }
    });

    Future.microtask(() => loadCart());
    return const CartState();
  }

  Future<void> loadCart() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = const CartState();
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final cartId = await _repository.getOrCreateCartId(user.id);
      final items = await _repository.getCartItems(cartId);
      state = CartState(cartId: cartId, items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تحميل سلة المشتريات: ${e.toString()}',
      );
    }
  }

  Future<bool> addToCart({
    required String productId,
    int quantity = 1,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final cartId = state.cartId ?? await _repository.getOrCreateCartId(user.id);
      await _repository.addItem(
        cartId: cartId,
        productId: productId,
        quantity: quantity,
      );
      final updatedItems = await _repository.getCartItems(cartId);
      state = CartState(cartId: cartId, items: updatedItems, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر إضافة المنتج إلى السلة: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> updateQuantity({
    required String cartItemId,
    required int newQuantity,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repository.updateQuantity(
        cartItemId: cartItemId,
        newQuantity: newQuantity,
      );
      if (state.cartId != null) {
        final items = await _repository.getCartItems(state.cartId!);
        state = CartState(cartId: state.cartId, items: items, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تحديث الكمية: ${e.toString()}',
      );
    }
  }

  Future<void> removeItem(String cartItemId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repository.removeItem(cartItemId);
      if (state.cartId != null) {
        final items = await _repository.getCartItems(state.cartId!);
        state = CartState(cartId: state.cartId, items: items, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر حذف العنصر: ${e.toString()}',
      );
    }
  }

  Future<void> clearCart() async {
    if (state.cartId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repository.clearCart(state.cartId!);
      state = CartState(cartId: state.cartId, items: const [], isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر إفراغ السلة: ${e.toString()}',
      );
    }
  }
}

final cartServiceProvider = Provider<CartService>((ref) {
  final client = Supabase.instance.client;
  return CartService(client);
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final service = ref.watch(cartServiceProvider);
  return CartRepository(service);
});

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
