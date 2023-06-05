import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_clone/common/enums/message_enum.dart';
import 'package:whatsapp_clone/common/providers/message_reply_provider.dart';
import 'package:whatsapp_clone/features/chat/controller/chat_controller.dart';
import 'package:whatsapp_clone/features/chat/widgets/my_message_card.dart';
import 'package:whatsapp_clone/features/chat/widgets/sender_message_card.dart';
import 'package:whatsapp_clone/models/message_model.dart';

import '../../../common/widgets/loader.dart';

class ChatList extends ConsumerStatefulWidget {
  final String receiverUserId;
  final bool isGroupChat;

  const ChatList({
    super.key,
    required this.receiverUserId,
    required this.isGroupChat,
  });

  @override
  ConsumerState createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<ChatList> {
  final ScrollController messageController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    messageController.dispose();
  }

  void onMessageSwipe(
    String message,
    bool isMe,
    MessageEnum messageEnum,
  ) {
    ref.read(messageReplyProvider.notifier).update((state) {
      return MessageReply(
        message: message,
        isMe: isMe,
        messageEnum: messageEnum,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Message>>(
        stream: widget.isGroupChat
            ? ref
                .read(chatControllerProvider)
                .getGroupStream(widget.receiverUserId)
            : ref
                .read(chatControllerProvider)
                .getChatStream(widget.receiverUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          SchedulerBinding.instance.addPostFrameCallback((_) {
            messageController
                .jumpTo(messageController.position.maxScrollExtent);
          });
          return ListView.builder(
            controller: messageController,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final messageData = snapshot.data![index];
              var timeSent = DateFormat.Hm().format(messageData.timeSent);
              var myUid = FirebaseAuth.instance.currentUser!.uid;

              if (!messageData.isSeen && messageData.receiverId == myUid) {
                ref.read(chatControllerProvider).setChatMessageSeen(
                      context,
                      widget.receiverUserId,
                      messageData.messageId,
                    );
              }
              if (messageData.senderId == myUid) {
                return MyMessageCard(
                  message: messageData.text,
                  date: timeSent,
                  type: messageData.type,
                  repliedText: messageData.repliedMessage,
                  username: messageData.repliedTo,
                  repliedMessageType: messageData.repliedMessageType,
                  onLeftSwipe: () {
                    return onMessageSwipe(
                      messageData.text,
                      true,
                      messageData.type,
                    );
                  },
                  isSeen: messageData.isSeen,
                );
              }
              return SenderMessageCard(
                message: messageData.text,
                date: timeSent,
                type: messageData.type,
                username: messageData.repliedTo,
                repliedMessageType: messageData.repliedMessageType,
                repliedText: messageData.repliedMessage,
                onRightSwipe: () {
                  return onMessageSwipe(
                    messageData.text,
                    false,
                    messageData.type,
                  );
                },
              );
            },
          );
        });
  }
}
