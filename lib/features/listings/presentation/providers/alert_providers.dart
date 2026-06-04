import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:max_food/features/listings/data/alert_repository.dart';
import 'package:max_food/features/listings/models/listing_alert_subscription_model.dart';
import 'package:max_food/features/listings/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final alertSubscriptionsProvider = AsyncNotifierProvider<AlertSubscriptionsNotifier, List<ListingAlertSubscriptionModel>>(
  AlertSubscriptionsNotifier.new,
);

class AlertSubscriptionsNotifier extends AsyncNotifier<List<ListingAlertSubscriptionModel>> {
  @override
  FutureOr<List<ListingAlertSubscriptionModel>> build() async {
    final repo = ref.watch(alertRepositoryProvider);
    return repo.getSubscriptions();
  }

  Future<void> toggleCategorySubscription(String categoryId, bool subscribe) async {
    final repo = ref.read(alertRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.toggleCategorySubscription(categoryId, subscribe);
      return repo.getSubscriptions();
    });
  }

  Future<void> toggleFarmerSubscription(String farmerId, bool subscribe) async {
    final repo = ref.read(alertRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.toggleFarmerSubscription(farmerId, subscribe);
      return repo.getSubscriptions();
    });
  }
}

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final repo = ref.watch(alertRepositoryProvider);
  final notifications = await repo.getNotifications();

  final userId = repo.currentUserId;
  if (userId != null) {
    final channel = Supabase.instance.client.channel('notifications_$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            ref.invalidateSelf();
          },
        )
        .subscribe();

    ref.onDispose(() {
      Supabase.instance.client.removeChannel(channel);
    });
  }

  return notifications;
});

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

final unreadMessageNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications
        .where((n) => n.type == 'new_message' && !n.isRead)
        .length,
    orElse: () => 0,
  );
});

class NotificationsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> markAsRead(String notificationId) async {
    final repo = ref.read(alertRepositoryProvider);
    await repo.markAsRead(notificationId);
    ref.invalidate(notificationsProvider);
  }

  Future<void> markAllAsRead() async {
    final repo = ref.read(alertRepositoryProvider);
    await repo.markAllAsRead();
    ref.invalidate(notificationsProvider);
  }
}

final notificationsControllerProvider = AsyncNotifierProvider<NotificationsController, void>(
  NotificationsController.new,
);
