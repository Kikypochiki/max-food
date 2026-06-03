class ProfileModel {
  final String id;
  final String? avatarUrl;
  final String? deliveryAddress;
  final DateTime? updatedAt;

  ProfileModel({
    required this.id,
    this.avatarUrl,
    this.deliveryAddress,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      avatarUrl: json['avatar_url'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avatar_url': avatarUrl,
      'delivery_address': deliveryAddress,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? avatarUrl,
    String? deliveryAddress,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
