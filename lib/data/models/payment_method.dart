class PaymentMethodModel {
  final String id;
  final String name;
  final String? accountName;
  final String? accountNumber;
  final String? instructions;
  final bool isActive;
  final int sortOrder;

  const PaymentMethodModel({
    required this.id,
    required this.name,
    this.accountName,
    this.accountNumber,
    this.instructions,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      name: json['name'] as String,
      accountName: json['account_name'] as String?,
      accountNumber: json['account_number'] as String?,
      instructions: json['instructions'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'account_name': accountName,
      'account_number': accountNumber,
      'instructions': instructions,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}
