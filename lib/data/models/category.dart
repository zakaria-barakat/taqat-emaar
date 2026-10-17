class Category {
  final String id;
  final String name;
  final String? parentId;
  final int sortOrder;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
    required this.sortOrder,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parent_id'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}