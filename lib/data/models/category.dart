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
}