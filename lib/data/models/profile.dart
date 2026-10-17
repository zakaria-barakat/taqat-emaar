class Profile {
  final String id;
  final String fullName;
  final String? phone;
  final DateTime? createdAt;

  const Profile({
    required this.id,
    required this.fullName,
    this.phone,
    this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      if (phone != null) 'phone': phone,
    };
  }

  Profile copyWith({
    String? fullName,
    String? phone,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }
}
