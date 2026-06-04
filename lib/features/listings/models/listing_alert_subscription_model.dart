class ListingAlertSubscriptionModel {
  final String id;
  final String userId;
  final String? categoryId;
  final String? farmerId;
  final DateTime createdAt;

  ListingAlertSubscriptionModel({
    required this.id,
    required this.userId,
    this.categoryId,
    this.farmerId,
    required this.createdAt,
  });

  factory ListingAlertSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return ListingAlertSubscriptionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      farmerId: json['farmer_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'farmer_id': farmerId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
