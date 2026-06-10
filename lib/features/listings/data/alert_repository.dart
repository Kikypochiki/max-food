import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:max_food/core/providers/supabase_providers.dart';
import 'package:max_food/features/listings/models/listing_alert_subscription_model.dart';
import 'package:max_food/features/listings/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertRepository {
  AlertRepository(this._client);
  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<ListingAlertSubscriptionModel>> getSubscriptions() async {
    final userId = currentUserId;
    if (userId == null) return [];
    try {
      final rows = await _client
          .from('listing_alerts_subscriptions')
          .select()
          .eq('user_id', userId);
      return (rows as List<dynamic>)
          .map((row) => ListingAlertSubscriptionModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> toggleCategorySubscription(String categoryId, bool subscribe) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('You must be logged in.');

    try {
      if (subscribe) {
        await _client.from('listing_alerts_subscriptions').insert({
          'user_id': userId,
          'category_id': categoryId,
        });
      } else {
        await _client
            .from('listing_alerts_subscriptions')
            .delete()
            .eq('user_id', userId)
            .eq('category_id', categoryId);
      }
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> toggleFarmerSubscription(String farmerId, bool subscribe) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('You must be logged in.');

    try {
      if (subscribe) {
        await _client.from('listing_alerts_subscriptions').insert({
          'user_id': userId,
          'farmer_id': farmerId,
        });
      } else {
        await _client
            .from('listing_alerts_subscriptions')
            .delete()
            .eq('user_id', userId)
            .eq('farmer_id', farmerId);
      }
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<NotificationModel>> getNotifications() async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final rows = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (rows as List<dynamic>)
          .map((row) => NotificationModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (_) {}
  }

  Stream<List<NotificationModel>> subscribeToNotifications() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) {
          final notifications =
              rows.map((row) => NotificationModel.fromJson(row)).toList();
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }
}

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository(ref.watch(supabaseClientProvider));
});
