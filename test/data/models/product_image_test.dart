import 'package:flutter_test/flutter_test.dart';
import 'package:taqat_emaar/data/models/product_image.dart';

void main() {
  group('ProductImage model', () {
    test('fromJson parses complete valid JSON from product_images table', () {
      final json = {
        'id': 'img-1',
        'product_id': 'prod-100',
        'url': 'https://example.com/panel.jpg',
        'sort_order': 1,
      };

      final image = ProductImage.fromJson(json);

      expect(image.id, 'img-1');
      expect(image.productId, 'prod-100');
      expect(image.url, 'https://example.com/panel.jpg');
      expect(image.sortOrder, 1);
    });

    test('fromJson handles optional product_id and default sort_order', () {
      final json = {
        'id': 'img-2',
        'url': 'https://example.com/panel-thumb.jpg',
      };

      final image = ProductImage.fromJson(json);

      expect(image.id, 'img-2');
      expect(image.productId, isNull);
      expect(image.url, 'https://example.com/panel-thumb.jpg');
      expect(image.sortOrder, 0);
    });

    test('toJson serializes correctly', () {
      const image = ProductImage(
        id: 'img-3',
        url: 'https://example.com/item.png',
        sortOrder: 3,
        productId: 'prod-200',
      );

      final json = image.toJson();

      expect(json, {
        'id': 'img-3',
        'url': 'https://example.com/item.png',
        'sort_order': 3,
        'product_id': 'prod-200',
      });
    });

    test('fromJson throws TypeError on missing required id or url', () {
      final invalidJson = {
        'sort_order': 1,
      };

      expect(() => ProductImage.fromJson(invalidJson), throwsA(isA<TypeError>()));
    });
  });
}