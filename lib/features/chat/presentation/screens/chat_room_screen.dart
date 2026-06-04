import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:max_food/features/auth/data/auth_repository.dart';
import 'package:max_food/features/chat/presentation/providers/chat_providers.dart';
import 'package:max_food/features/chat/data/chat_repository.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({required this.roomId, super.key});

  final String roomId;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() {
      _isSending = true;
    });

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            roomId: widget.roomId,
            messageText: text,
          );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final roomDetailsAsync = ref.watch(chatRoomDetailsProvider(widget.roomId));
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.roomId));
    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.id;

    // Trigger auto-scroll on new message emissions
    ref.listen(chatMessagesStreamProvider(widget.roomId), (prev, next) {
      next.whenData((_) {
        // Mark as read when new messages arrive while in room
        ref.read(chatRepositoryProvider).markMessagesAsRead(widget.roomId);
        _scrollToBottom();
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F3),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: const Color(0xFF2A8F3A),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: const Color(0xFF2A8F3A),
        title: roomDetailsAsync.when(
          data: (room) {
            final isBuyer = currentUserId == room.buyerId;
            final otherUser = isBuyer ? room.seller : room.buyer;
            final otherUserName = otherUser?.fullName?.trim().isNotEmpty == true
                ? otherUser!.fullName!.trim()
                : 'UbayHarvest Farmer';
            final avatarUrl = otherUser?.avatarUrl?.trim();

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 20, color: Color(0xFF2A8F3A))
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        otherUserName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isBuyer ? 'Seller' : 'Buyer',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE4F5E7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Text('Loading chat...'),
          error: (err, stack) => const Text('Chat Room'),
        ),
      ),
      body: Column(
        children: [
          // Listing Context Header
          roomDetailsAsync.when(
            data: (room) {
              final listing = room.listing;
              if (listing == null) return const SizedBox.shrink();
              final listingImageUrl = listing.imageUrl?.trim();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFD8E8DA)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(6),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D4F2A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PHP ${listing.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF186A3B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/listings/${listing.listingId}'),
                      icon: const Icon(Icons.arrow_forward_ios, size: 12),
                      label: const Text('View Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2A8F3A),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),

          // Messages View
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Start the conversation by typing below.',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }

                // Scroll to bottom once messages load
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOutgoing = message.senderId == currentUserId;

                    return Align(
                      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isOutgoing ? const Color(0xFF2A8F3A) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isOutgoing ? 16 : 2),
                            bottomRight: Radius.circular(isOutgoing ? 2 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ],
                          border: isOutgoing
                              ? null
                              : Border.all(color: const Color(0xFFD8E8DA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              message.message,
                              style: TextStyle(
                                color: isOutgoing ? Colors.white : const Color(0xFF1D4F2A),
                                fontSize: 14.5,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatMessageTime(message.createdAt),
                              style: TextStyle(
                                color: isOutgoing ? const Color(0xFFE4F5E7) : const Color(0xFF8C9E92),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF2A8F3A)),
              ),
              error: (error, _) => Center(
                child: Text(
                  'Failed to stream messages: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),

          // Message Input Bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF2F8F3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF2A8F3A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
