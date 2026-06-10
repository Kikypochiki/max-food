import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:max_food/features/chat/data/chat_repository.dart';
import 'package:max_food/features/chat/models/chat_message_model.dart';
import 'package:max_food/features/chat/models/chat_room_model.dart';

final chatRoomsProvider = FutureProvider.autoDispose<List<ChatRoomModel>>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getChatRooms();
});

final chatRoomDetailsProvider = FutureProvider.family.autoDispose<ChatRoomModel, String>((ref, roomId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getRoomDetails(roomId);
});

final chatMessagesStreamProvider = StreamProvider.family.autoDispose<List<ChatMessageModel>, String>((ref, roomId) {
  final repo = ref.watch(chatRepositoryProvider);
  // Mark messages in the room as read upon opening/listening
  repo.markMessagesAsRead(roomId);
  
  // Return the realtime database stream
  return repo.subscribeToMessages(roomId);
});
