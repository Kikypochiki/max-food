import 'package:max_food/features/profile/models/profile_model.dart';
import 'package:max_food/features/listings/data/listing_repository.dart';

class ChatRoomModel {
  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final DateTime createdAt;
  
  // Joined fields
  final ListingItem? listing;
  final ProfileModel? buyer;
  final ProfileModel? seller;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  ChatRoomModel({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.createdAt,
    this.listing,
    this.buyer,
    this.seller,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    final listingData = json['listing'] as Map<String, dynamic>?;
    final buyerData = json['buyer'] as Map<String, dynamic>?;
    final sellerData = json['seller'] as Map<String, dynamic>?;

    return ChatRoomModel(
      id: json['id'] as String,
      listingId: json['listing_id'].toString(),
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      listing: listingData != null ? ListingItem.fromRow(listingData) : null,
      buyer: buyerData != null ? ProfileModel.fromJson(buyerData) : null,
      seller: sellerData != null ? ProfileModel.fromJson(sellerData) : null,
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_id': int.tryParse(listingId) ?? listingId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
