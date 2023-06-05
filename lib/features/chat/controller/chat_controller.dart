import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/common/enums/message_enum.dart';
import 'package:whatsapp_clone/common/providers/message_reply_provider.dart';
import 'package:whatsapp_clone/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_clone/features/chat/repository/chat_repository.dart';
import 'package:whatsapp_clone/models/chat_contact_model.dart';
import 'package:whatsapp_clone/models/group_model.dart';

import '../../../models/message_model.dart';

final chatControllerProvider = Provider((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return ChatController(
    chatRepository: chatRepository,
    ref: ref,
  );
});

class ChatController {
  final ChatRepository chatRepository;
  final ProviderRef ref;

  ChatController({
    required this.chatRepository,
    required this.ref,
  });

  Stream<List<ChatContact>> getChatContacts() {
    return chatRepository.getChatContacts();
  }

  Stream<List<GroupModel>> getChatGroups() {
    return chatRepository.getChatGroups();
  }

  Stream<List<Message>> getChatStream(String receiverUserId) {
    return chatRepository.getChatStream(receiverUserId);
  }

  Stream<List<Message>> getGroupStream(String groupId) {
    return chatRepository.getGroupStream(groupId);
  }

  void sendTextMessage(
    BuildContext context,
    String text,
    String receiverUserId,
    bool isGroupChat,
  ) {
    final messageReply = ref.read(messageReplyProvider);
    ref.read(userDataAuthProvider).whenData((value) {
      return chatRepository.sentTextMessage(
        context: context,
        text: text,
        receiverUserId: receiverUserId,
        senderUser: value!,
        messageReply: messageReply,
        isGroupChat: isGroupChat,
      );
    });
    ref.read(messageReplyProvider.notifier).update((state) => null);
  }

  void sendFileMessage(
    BuildContext context,
    File file,
    String receiverUserId,
    MessageEnum messageEnum,
    bool isGroupChat,
  ) {
    final messageReply = ref.read(messageReplyProvider);
    ref.read(userDataAuthProvider).whenData((value) {
      return chatRepository.sendFileMessage(
        context: context,
        file: file,
        receiverUserId: receiverUserId,
        senderUserData: value!,
        ref: ref,
        messageEnum: messageEnum,
        messageReply: messageReply,
        isGroupChat: isGroupChat,
      );
    });
    ref.read(messageReplyProvider.notifier).update((state) => null);
  }

  void sentGIFMessage(
    BuildContext context,
    String gifUrl,
    String receiverUserId,
    bool isGroupChat,
  ) {
    int gifUrlPartIndex = gifUrl.lastIndexOf('-') + 1;
    String gifUrlPart = gifUrl.substring(gifUrlPartIndex);
    String newGifUrl = 'https://i.giphy.com/media/$gifUrlPart/200.gif';

    final messageReply = ref.read(messageReplyProvider);

    ref.read(userDataAuthProvider).whenData((value) {
      return chatRepository.sentGIFMessage(
        context: context,
        gifUrl: newGifUrl,
        receiverUserId: receiverUserId,
        senderUser: value!,
        messageReply: messageReply,
        isGroupChat: isGroupChat,
      );
    });
    ref.read(messageReplyProvider.notifier).update((state) => null);
  }

  void setChatMessageSeen(
    BuildContext context,
    String receiverUserId,
    String messageId,
  ) {
    chatRepository.setChatMessageSeen(
      context: context,
      receiverUserId: receiverUserId,
      messageId: messageId,
    );
  }
}
