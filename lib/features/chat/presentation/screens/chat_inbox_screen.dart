import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:max_food/features/auth/data/auth_repository.dart';
import 'package:max_food/features/chat/presentation/providers/chat_providers.dart';

class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${local.month}/${local.day}/${local.year}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(chatRoomsProvider);
    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F3),
      appBar: AppBar(
        title: const Text(
          'Inbox',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF2A8F3A),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: const Color(0xFF2A8F3A),
      ),
      body: roomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.green[200],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No conversations yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4F2A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Messages about items you buy or sell will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF667A6C),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF2A8F3A),
            onRefresh: () async {
              ref.invalidate(chatRoomsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                
                // Determine whether current user is buyer or seller
                final isBuyer = currentUserId == room.buyerId;
                final otherUser = isBuyer ? room.seller : room.buyer;
                final otherUserName = otherUser?.fullName?.trim().isNotEmpty == true
                    ? otherUser!.fullName!.trim()
                    : 'UbayHarvest User';
                final otherUserAvatar = otherUser?.avatarUrl?.trim();
                
                final listing = room.listing;
                final listingName = listing?.name ?? 'Untitled Listing';
                final listingImageUrl = listing?.imageUrl?.trim();

                final lastMsg = room.lastMessage ?? 'No messages yet';
                final lastMsgTime = _formatTime(room.lastMessageTime ?? room.createdAt);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFD8E8DA)),
                  ),
                  color: Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push('/chat/room/${room.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Other participant's Avatar
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFE7F4E9),
                            backgroundImage: otherUserAvatar != null && otherUserAvatar.isNotEmpty
                                ? NetworkImage(otherUserAvatar)
                                : null,
                            child: otherUserAvatar == null || otherUserAvatar.isEmpty
                                ? const Icon(Icons.person, color: Color(0xFF2A8F3A))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          // Text Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Other user name & Time
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      otherUserName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Color(0xFF1D4F2A),
                                      ),
                                    ),
                                    Text(
                                      lastMsgTime,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF8C9E92),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Product Reference tag
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7F4E9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Product: $listingName',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF186A3B),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Last message snippet
                                Text(
                                  lastMsg,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF556259),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Listing thumbnail
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: listingImageUrl == null || listingImageUrl.isEmpty
                                ? Image.asset('assets/images/logo_ubayharvest1.png', fit: BoxFit.cover)
                                : Image.network(
                                    listingImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                      'assets/images/logo_ubayharvest1.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Failed to load inbox: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
