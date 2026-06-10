import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:max_food/features/auth/data/auth_repository.dart';
import 'package:max_food/features/listings/data/listing_repository.dart';
import 'package:max_food/features/listings/presentation/providers/listing_providers.dart';
import 'package:max_food/features/profile/providers/profile_provider.dart';
import 'package:max_food/features/chat/data/chat_repository.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({required this.listingId, super.key});

  final String listingId;

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  final _messageController = TextEditingController(text: 'Hi, is this available?');
  bool _isCreatingRoom = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _startChat(ListingItem listing) async {
    setState(() {
      _isCreatingRoom = true;
    });

    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final room = await chatRepo.getOrCreateRoom(
        listingId: listing.listingId,
        sellerId: listing.farmerUserId,
      );

      final draftMessage = _messageController.text.trim();
      if (draftMessage.isNotEmpty) {
        await chatRepo.sendMessage(
          roomId: room.id,
          messageText: draftMessage,
        );
      }

      if (!mounted) return;
      context.push('/chat/room/${room.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingRoom = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(singleListingProvider(widget.listingId));
    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F3),
      appBar: AppBar(
        title: const Text(
          'Listing Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF2A8F3A),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: const Color(0xFF2A8F3A),
      ),
      body: listingAsync.when(
        data: (listing) {
          if (listing == null) {
            return const Center(child: Text('Listing not found'));
          }

          final isOwner = currentUserId == listing.farmerUserId;
          final statusColor = switch (listing.status.toLowerCase()) {
            'sold' => Colors.red.shade600,
            'hidden' => Colors.grey.shade400,
            _ => const Color(0xFF2A8F3A),
          };

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Listing Image
                Container(
                  color: Colors.white,
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: listing.imageUrl == null || listing.imageUrl!.isEmpty
                        ? Image.asset(
                            'assets/images/logo_ubayharvest1.png',
                            fit: BoxFit.contain,
                          )
                        : Image.network(
                            listing.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/logo_ubayharvest1.png',
                                fit: BoxFit.contain,
                              );
                            },
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PHP ${listing.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF186A3B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
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
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Title
                      Text(
                        listing.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4F2A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Category & Location
                      Row(
                        children: [
                          Icon(Icons.category_outlined, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            listing.categoryName,
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              listing.location?.trim().isNotEmpty == true
                                  ? listing.location!.trim()
                                  : 'No location provided',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Quantity
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Available Quantity: ${listing.quantity}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1.2),
                      
                      // Description Card
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4F2A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD8E8DA)),
                        ),
                        child: Text(
                          listing.description.trim().isNotEmpty
                              ? listing.description.trim()
                              : 'No description provided.',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      const Divider(height: 24, thickness: 1.2),

                      // Seller Card
                      const Text(
                        'Seller Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4F2A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer(
                        builder: (context, ref, child) {
                          final sellerAsync = ref.watch(otherProfileProvider(listing.farmerUserId));
                          return sellerAsync.when(
                            data: (sellerProfile) {
                              final sellerName = sellerProfile?.fullName?.trim().isNotEmpty == true
                                  ? sellerProfile!.fullName!.trim()
                                  : 'UbayHarvest Farmer';
                              final avatarUrl = sellerProfile?.avatarUrl?.trim();
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFD8E8DA)),
                                ),
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
                                            sellerName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1D4F2A),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            isOwner ? 'You are the seller of this listing' : 'Verified Farmer',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isOwner ? Colors.blue[700] : const Color(0xFF667A6C),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      onPressed: () => context.push('/farmers/${listing.farmerUserId}/listings'),
                                      icon: const Icon(Icons.storefront_outlined),
                                      tooltip: 'View Seller Store',
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFFE7F4E9),
                                        foregroundColor: const Color(0xFF2A8F3A),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(color: Color(0xFF2A8F3A)),
                            ),
                            error: (err, stack) => const Text('Failed to load seller details'),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),

                      // Chat / Action Section
                      if (isOwner) ...[
                        FilledButton.icon(
                          onPressed: () => context.push('/farmers/${listing.farmerUserId}/listings'),
                          icon: const Icon(Icons.store),
                          label: const Text('Manage My Listings'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2A8F3A),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                              )
                            ],
                            border: Border.all(color: const Color(0xFFD8E8DA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Send a message to the seller',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF1D4F2A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Enter your message...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _isCreatingRoom ? null : () => _startChat(listing),
                                icon: _isCreatingRoom
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.chat_bubble_outline),
                                label: Text(_isCreatingRoom ? 'Creating Chat...' : 'Send Message'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF2A8F3A),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2A8F3A)),
        ),
        error: (error, _) => Center(
          child: Text(
            'Failed to load details: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
