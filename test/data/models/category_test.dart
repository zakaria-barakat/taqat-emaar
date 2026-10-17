import 'package:flutter_test/flutter_test.dart';
import 'package:taqat_emaar/data/models/category.dart';

void main() {
  group('Category model', () {
    test('fromJson parses complete valid JSON correctly', () {
      final json = {
        'id': 'cat-123',
        'name': 'Solar Panels',
        'parent_id': 'cat-root',
        'sort_order': 5,
        'is_active': true,
      };

      final category = Category.fromJson(json);

      expect(category.id, 'cat-123');
      expect(category.name, 'Solar Panels');
      expect(category.parentId, 'cat-root');
      expect(category.sortOrder, 5);
      expect(category.isActive, isTrue);
    });

    test('fromJson handles nullable and default values properly', () {
      final json = {
        'id': 'cat-456',
        'name': 'Inverters',
      };

      final category = Category.fromJson(json);

      expect(category.id, 'cat-456');
      expect(category.name, 'Inverters');
      expect(category.parentId, isNull);
      expect(category.sortOrder, 0);
      expect(category.isActive, isTrue);
    });

    test('toJson serializes correctly', () {
      const category = Category(
        id: 'cat-789',
        name: 'Batteries',
        parentId: 'cat-root',
        sortOrder: 2,
        isActive: false,
      );

      final json = category.toJson();

      expect(json, {
        'id': 'cat-789',
        'name': 'Batteries',
        'parent_id': 'cat-root',
        'sort_order': 2,
        'is_active': false,
      });
    });

    test('fromJson throws TypeError on invalid or missing required field', () {
      final invalidJson = {
        'name': 'Missing ID Category',
      };

      expect(() => Category.fromJson(invalidJson), throwsA(isA<TypeError>()));
    });
  });
}