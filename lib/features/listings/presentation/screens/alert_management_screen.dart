import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:max_food/features/listings/presentation/providers/alert_providers.dart';
import 'package:max_food/features/listings/presentation/providers/listing_providers.dart';
import 'package:max_food/features/profile/providers/profile_provider.dart';

class AlertManagementScreen extends ConsumerWidget {
  const AlertManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F8F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2A8F3A),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Manage Listing Alerts',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFC2E2C8),
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            tabs: [
              Tab(text: 'Categories', icon: Icon(Icons.category_outlined)),
              Tab(text: 'Farmers', icon: Icon(Icons.storefront_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CategorySubscriptionsTab(),
            _FarmerSubscriptionsTab(),
          ],
        ),
      ),
    );
  }
}

class _CategorySubscriptionsTab extends ConsumerWidget {
  const _CategorySubscriptionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final subsAsync = ref.watch(alertSubscriptionsProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text('No categories available'));
        }

        return subsAsync.when(
          data: (subs) {
            final subscribedCategoryIds = subs
                .where((sub) => sub.categoryId != null)
                .map((sub) => sub.categoryId!)
                .toSet();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSubscribed = subscribedCategoryIds.contains(category.id);

                return Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFD8E8DA)),
                  ),
                  child: SwitchListTile(
                    activeThumbColor: const Color(0xFF2A8F3A),
                    activeTrackColor: const Color(0xFFC2E2C8),
                    title: Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4F2A),
                      ),
                    ),
                    subtitle: Text(
                      isSubscribed
                          ? 'Notifying you on new posts'
                          : 'Get alerts on new posts',
                      style: const TextStyle(
                        color: Color(0xFF667A6C),
                        fontSize: 13,
                      ),
                    ),
                    value: isSubscribed,
                    onChanged: (value) async {
                      try {
                        await ref
                            .read(alertSubscriptionsProvider.notifier)
                            .toggleCategorySubscription(category.id, value);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update alert: $e')),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF2A8F3A)),
          ),
          error: (err, _) => Center(child: Text('Error loading alerts: $err')),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2A8F3A)),
      ),
      error: (err, _) => Center(child: Text('Error loading categories: $err')),
    );
  }
}

class _FarmerSubscriptionsTab extends ConsumerWidget {
  const _FarmerSubscriptionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(alertSubscriptionsProvider);

    return subsAsync.when(
      data: (subs) {
        final farmerSubs = subs.where((sub) => sub.farmerId != null).toList();

        if (farmerSubs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'You are not following any farmers.\nGo to a farmer\'s store and click "Alert Me" to get notifications for their new listings!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF667A6C),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: farmerSubs.length,
          itemBuilder: (context, index) {
            final sub = farmerSubs[index];
            return _FarmerSubscriptionRow(farmerId: sub.farmerId!);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2A8F3A)),
      ),
      error: (err, _) => Center(child: Text('Error loading alerts: $err')),
    );
  }
}

class _FarmerSubscriptionRow extends ConsumerWidget {
  const _FarmerSubscriptionRow({required this.farmerId});

  final String farmerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(otherProfileProvider(farmerId));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final farmerName = profile.fullName?.trim().isNotEmpty == true
            ? profile.fullName!.trim()
            : 'UbayHarvest Farmer';
        final avatarUrl = profile.avatarUrl?.trim();

        return Card(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFD8E8DA)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE7F4E9),
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(Icons.person, color: Color(0xFF2A8F3A))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1D4F2A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Alerting you on new posts',
                        style: TextStyle(
                          color: Color(0xFF667A6C),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(alertSubscriptionsProvider.notifier)
                          .toggleFarmerSubscription(farmerId, false);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to unsubscribe: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.notifications_off_outlined),
                  color: const Color(0xFFB3261E),
                  tooltip: 'Unfollow/Mute Alerts',
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2A8F3A)),
          ),
        ),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
