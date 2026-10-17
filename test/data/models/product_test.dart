import 'package:flutter_test/flutter_test.dart';
import 'package:taqat_emaar/data/models/product.dart';
import 'package:taqat_emaar/data/models/product_image.dart';

void main() {
  group('Product model', () {
    test('fromJson parses complete valid JSON with nested product_images', () {
      final json = {
        'id': 'prod-1',
        'name': 'Monocrystalline Solar Panel 550W',
        'description': 'High efficiency tier-1 panel',
        'price': 135.50,
        'currency': 'USD',
        'stock_quantity': 50,
        'category_id': 'cat-solar',
        'selling_unit': 'piece',
        'is_active': true,
        'product_images': [
          {
            'id': 'img-1',
            'product_id': 'prod-1',
            'url': 'https://example.com/solar1.jpg',
            'sort_order': 0,
          },
          {
            'id': 'img-2',
            'product_id': 'prod-1',
            'url': 'https://example.com/solar2.jpg',
            'sort_order': 1,
          },
        ],
      };

      final product = Product.fromJson(json);

      expect(product.id, 'prod-1');
      expect(product.name, 'Monocrystalline Solar Panel 550W');
      expect(product.description, 'High efficiency tier-1 panel');
      expect(product.price, 135.50);
      expect(product.currency, 'USD');
      expect(product.stockQuantity, 50);
      expect(product.categoryId, 'cat-solar');
      expect(product.sellingUnit, 'piece');
      expect(product.isActive, isTrue);
      expect(product.images.length, 2);
      expect(product.images.first.id, 'img-1');
      expect(product.images.last.url, 'https://example.com/solar2.jpg');
    });

    test('fromJson converts integer price to double properly', () {
      final json = {
        'id': 'prod-2',
        'name': 'Battery Cable 25mm',
        'description': 'Copper heavy duty',
        'price': 2500, // integer from PostgreSQL NUMERIC or count
        'currency': 'YER',
        'stock_quantity': 100,
        'category_id': 'cat-accessories',
        'selling_unit': 'meter',
        'is_active': true,
      };

      final product = Product.fromJson(json);

      expect(product.price, 2500.0);
      expect(product.price, isA<double>());
    });

    test('fromJson handles optional fields and empty images gracefully', () {
      final json = {
        'id': 'prod-3',
        'name': 'Circuit Breaker 63A',
        'price': 15.0,
        'category_id': 'cat-protection',
      };

      final product = Product.fromJson(json);

      expect(product.id, 'prod-3');
      expect(product.name, 'Circuit Breaker 63A');
      expect(product.description, '');
      expect(product.currency, 'YER');
      expect(product.stockQuantity, 0);
      expect(product.sellingUnit, '');
      expect(product.isActive, isTrue);
      expect(product.images, isEmpty);
    });

    test('toJson serializes correctly including nested images', () {
      const product = Product(
        id: 'prod-4',
        name: 'Hybrid Inverter 5kW',
        description: 'Pure sine wave',
        price: 650.0,
        currency: 'USD',
        stockQuantity: 10,
        categoryId: 'cat-inverters',
        sellingUnit: 'piece',
        isActive: true,
        images: [
          ProductImage(
            id: 'img-inv-1',
            url: 'https://example.com/inverter.jpg',
            sortOrder: 1,
            productId: 'prod-4',
          ),
        ],
      );

      final json = product.toJson();

      expect(json['id'], 'prod-4');
      expect(json['price'], 650.0);
      expect(json['product_images'], isA<List>());
      final images = json['product_images'] as List;
      expect(images.length, 1);
      expect(images.first['id'], 'img-inv-1');
    });

    test('fromJson throws TypeError on missing or invalid required fields', () {
      final invalidJson = {
        'name': 'No price or id product',
      };

      expect(() => Product.fromJson(invalidJson), throwsA(isA<TypeError>()));
    });
  });
}