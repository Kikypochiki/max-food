import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:max_food/features/auth/data/auth_repository.dart';
import 'package:max_food/features/listings/data/listing_repository.dart';
import 'package:max_food/features/listings/presentation/providers/listing_providers.dart';
import 'package:max_food/features/listings/models/notification_model.dart';
import 'package:max_food/features/listings/presentation/providers/alert_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildListingCard(
    BuildContext context,
    ListingItem listing,
    bool isOwner,
  ) {
    final statusColor = switch (listing.status.toLowerCase()) {
      'sold' => Colors.red.shade600,
      'hidden' => Colors.grey.shade400,
      _ => const Color(0xFF2A8F3A),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/listings/${listing.listingId}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      color: const Color(0xFFF0F0F0),
                      child:
                          listing.imageUrl == null || listing.imageUrl!.isEmpty
                          ? Image.asset(
                              'assets/images/logo_ubayharvest1.png',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              listing.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/logo_ubayharvest1.png',
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                    ),
                  ),
                  if (listing.status.toLowerCase() != 'available')
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            listing.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PHP ${listing.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF186A3B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      listing.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Color(0xFF1D4F2A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      listing.location?.isEmpty ?? true
                          ? listing.categoryName
                          : listing.location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF667A6C),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<NotificationModel>>>(
      notificationsProvider,
      (previous, next) {
        final prevList = previous?.valueOrNull;
        final nextList = next.valueOrNull;

        if (nextList != null && prevList != null && nextList.length > prevList.length) {
          final newNotifications = nextList
              .where((item) => !prevList.any((prev) => prev.id == item.id))
              .toList();
          for (final notification in newNotifications) {
            if (!notification.isRead) {
              _showInAppNotificationBanner(context, notification);
            }
          }
        }
      },
    );

    final user = ref.watch(authRepositoryProvider).currentUser;
    final listingsAsync = ref.watch(filteredMarketplaceListingsProvider);
    final query = ref.watch(listingSearchQueryProvider);

    if (_searchController.text != query) {
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A8F3A),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: const Color(0xFF2A8F3A),
        titleSpacing: 0,
        leading: Container(
          padding: const EdgeInsets.only(left: 12),
          alignment: Alignment.centerLeft,
          child: const Text(
            'UbayHarvest',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        leadingWidth: 160,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 26),
            tooltip: 'Create listing',
            onPressed: () => context.push('/listings/create'),
          ),
          IconButton(
            icon: const Icon(Icons.store_outlined, size: 26),
            tooltip: 'My listings',
            onPressed: user == null
                ? null
                : () => context.push('/farmers/${user.id}/listings'),
          ),
          Consumer(
            builder: (context, ref, child) {
              final unreadMsgs = ref.watch(unreadMessageNotificationsCountProvider);
              return Badge(
                isLabelVisible: unreadMsgs > 0,
                label: Text(unreadMsgs.toString()),
                backgroundColor: const Color(0xFFB3261E),
                child: IconButton(
                  icon: const Icon(Icons.chat_outlined, size: 26),
                  tooltip: 'Inbox',
                  onPressed: () => context.push('/chat/inbox'),
                ),
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final unreadAlerts = ref.watch(unreadNotificationsCountProvider);
              return Badge(
                isLabelVisible: unreadAlerts > 0,
                label: Text(unreadAlerts.toString()),
                backgroundColor: const Color(0xFFB3261E),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 26),
                  tooltip: 'Notifications',
                  onPressed: () => context.push('/notifications'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 26),
            tooltip: 'My Profile',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              color: const Color(0xFF2A8F3A),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) =>
                    ref.read(listingSearchQueryProvider.notifier).state = value,
                decoration: InputDecoration(
                  hintText: 'Search vegetables, fruits, rice...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF80868B),
                  ),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () =>
                              ref
                                      .read(listingSearchQueryProvider.notifier)
                                      .state =
                                  '',
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintStyle: const TextStyle(color: Color(0xFF667A6C)),
                ),
              ),
            ),
            Expanded(
              child: listingsAsync.when(
                data: (listings) {
                  if (listings.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No listings found.\nTry adding your first product.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF667A6C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF2A8F3A),
                    onRefresh: () async {
                      ref.invalidate(marketplaceListingsProvider);
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth >= 1080
                            ? 4
                            : constraints.maxWidth >= 760
                            ? 3
                            : 2;

                        return GridView.builder(
                          padding: const EdgeInsets.all(10),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: listings.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.65,
                              ),
                          itemBuilder: (context, index) {
                            final listing = listings[index];
                            final isOwner = user?.id == listing.farmerUserId;
                            return _buildListingCard(context, listing, isOwner);
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2A8F3A)),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Could not load listings.\n$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInAppNotificationBanner(BuildContext context, NotificationModel notification) {
    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 10,
        left: 0,
        right: 0,
        child: InAppNotificationToast(
          notification: notification,
          onDismiss: () => overlayEntry.remove(),
          onTap: () {
            ref.read(notificationsControllerProvider.notifier).markAsRead(notification.id);
            
            final data = notification.data;
            if (notification.type == 'new_listing' && data != null) {
              final listingId = data['listing_id']?.toString();
              if (listingId != null) {
                context.push('/listings/$listingId');
              }
            } else if (notification.type == 'new_message' && data != null) {
              final roomId = data['room_id']?.toString();
              if (roomId != null) {
                context.push('/chat/room/$roomId');
              }
            }
          },
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }
}

class InAppNotificationToast extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const InAppNotificationToast({
    required this.notification,
    required this.onDismiss,
    required this.onTap,
    super.key,
  });

  @override
  State<InAppNotificationToast> createState() => _InAppNotificationToastState();
}

class _InAppNotificationToastState extends State<InAppNotificationToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.notification.type == 'new_message'
        ? Icons.chat_bubble_outline
        : Icons.notifications_active_outlined;

    return SlideTransition(
      position: _offsetAnimation,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                widget.onTap();
                _dismiss();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFC2E2C8), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE7F4E9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: const Color(0xFF2A8F3A), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFF1D4F2A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.notification.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4A5A4F),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Color(0xFF667A6C)),
                      onPressed: _dismiss,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
