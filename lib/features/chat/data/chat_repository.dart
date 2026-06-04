import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:max_food/core/providers/supabase_providers.dart';
import 'package:max_food/features/chat/models/chat_message_model.dart';
import 'package:max_food/features/chat/models/chat_room_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<ChatRoomModel>> getChatRooms() async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('chat_rooms')
          .select('''
            id,
            listing_id,
            buyer_id,
            seller_id,
            created_at,
            listing:listing_id (
              listing_id,
              farmer_user_id,
              product_id,
              price,
              quantity,
              date_posted,
              status,
              image_url,
              location,
              product:product_id (
                product_id,
                name,
                description,
                category_id,
                category:category_id (name)
              )
            ),
            buyer:buyer_id (
              id,
              full_name,
              avatar_url,
              delivery_address,
              updated_at
            ),
            seller:seller_id (
              id,
              full_name,
              avatar_url,
              delivery_address,
              updated_at
            )
          ''')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('created_at', ascending: false);

      final rooms = (response as List<dynamic>)
          .map((row) => ChatRoomModel.fromJson(row as Map<String, dynamic>))
          .toList();

      final List<ChatRoomModel> populatedRooms = [];
      for (final room in rooms) {
        final lastMsgRes = await _client
            .from('chat_messages')
            .select('message, created_at')
            .eq('room_id', room.id)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (lastMsgRes != null) {
          populatedRooms.add(ChatRoomModel(
            id: room.id,
            listingId: room.listingId,
            buyerId: room.buyerId,
            sellerId: room.sellerId,
            createdAt: room.createdAt,
            listing: room.listing,
            buyer: room.buyer,
            seller: room.seller,
            lastMessage: lastMsgRes['message'] as String?,
            lastMessageTime: lastMsgRes['created_at'] != null
                ? DateTime.parse(lastMsgRes['created_at'] as String)
                : null,
          ));
        } else {
          populatedRooms.add(room);
        }
      }

      populatedRooms.sort((a, b) {
        final timeA = a.lastMessageTime ?? a.createdAt;
        final timeB = b.lastMessageTime ?? b.createdAt;
        return timeB.compareTo(timeA);
      });

      return populatedRooms;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<ChatRoomModel> getRoomDetails(String roomId) async {
    try {
      final response = await _client
          .from('chat_rooms')
          .select('''
            id,
            listing_id,
            buyer_id,
            seller_id,
            created_at,
            listing:listing_id (
              listing_id,
              farmer_user_id,
              product_id,
              price,
              quantity,
              date_posted,
              status,
              image_url,
              location,
              product:product_id (
                product_id,
                name,
                description,
                category_id,
                category:category_id (name)
              )
            ),
            buyer:buyer_id (
              id,
              full_name,
              avatar_url,
              delivery_address,
              updated_at
            ),
            seller:seller_id (
              id,
              full_name,
              avatar_url,
              delivery_address,
              updated_at
            )
          ''')
          .eq('id', roomId)
          .single();

      return ChatRoomModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<ChatRoomModel> getOrCreateRoom({
    required String listingId,
    required String sellerId,
  }) async {
    final buyerId = currentUserId;
    if (buyerId == null) {
      throw Exception('You must be logged in to chat with the seller.');
    }

    if (buyerId == sellerId) {
      throw Exception('You cannot chat with yourself about your own listing.');
    }

    if (listingId.trim().isEmpty) {
      throw Exception('Invalid listing ID.');
    }

    try {
      final existing = await _client
          .from('chat_rooms')
          .select()
          .eq('listing_id', listingId)
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId)
          .maybeSingle();

      if (existing != null) {
        return getRoomDetails(existing['id'] as String);
      }

      final inserted = await _client
          .from('chat_rooms')
          .insert({
            'listing_id': listingId,
            'buyer_id': buyerId,
            'seller_id': sellerId,
          })
          .select()
          .single();

      return getRoomDetails(inserted['id'] as String);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> sendMessage({
    required String roomId,
    required String messageText,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    try {
      await _client.from('chat_messages').insert({
        'room_id': roomId,
        'sender_id': userId,
        'message': messageText.trim(),
        'is_read': false,
      });
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Stream<List<ChatMessageModel>> subscribeToMessages(String roomId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .map((rows) {
          final msgs = rows.map((row) => ChatMessageModel.fromJson(row)).toList();
          msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return msgs;
        });
  }

  Future<void> markMessagesAsRead(String roomId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _client
          .from('chat_messages')
          .update({'is_read': true})
          .eq('room_id', roomId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (_) {
      // Fail silently for read status marking
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});
