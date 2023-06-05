import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_clone/common/enums/message_enum.dart';
import 'package:whatsapp_clone/common/providers/message_reply_provider.dart';
import 'package:whatsapp_clone/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapp_clone/common/utils/utils.dart';
import 'package:whatsapp_clone/models/chat_contact_model.dart';
import 'package:whatsapp_clone/models/group_model.dart';
import 'package:whatsapp_clone/models/message_model.dart';
import 'package:whatsapp_clone/models/user_model.dart';

final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

class ChatRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  ChatRepository({required this.auth, required this.firestore});

  Stream<List<ChatContact>> getChatContacts() {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .snapshots()
        .asyncMap((event) async {
      List<ChatContact> contacts = [];
      for (var document in event.docs) {
        var chatContact = ChatContact.fromMap(document.data());
        var userData = await firestore
            .collection('users')
            .doc(chatContact.contactId)
            .get();
        var user = UserModel.fromMap(userData.data()!);
        contacts.add(
          ChatContact(
            name: user.name,
            profilePic: user.profilePic,
            contactId: chatContact.contactId,
            timeSent: chatContact.timeSent,
            lastMessage: chatContact.lastMessage,
          ),
        );
      }
      return contacts;
    });
  }

  Stream<List<GroupModel>> getChatGroups() {
    return firestore.collection('groups').snapshots().map((event) {
      List<GroupModel> groups = [];
      for (var document in event.docs) {
        var groupData = GroupModel.fromMap(document.data());

        if (groupData.membersUid.contains(auth.currentUser!.uid)) {
          groups.add(groupData);
        }
      }
      return groups;
    });
  }

  Stream<List<Message>> getChatStream(String receiverUserId) {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(receiverUserId)
        .collection('messages')
        .orderBy('timeSent')
        .snapshots()
        .map((event) {
      List<Message> messages = [];
      for (var document in event.docs) {
        messages.add(Message.fromMap(document.data()));
      }
      return messages;
    });
  }

  Stream<List<Message>> getGroupStream(String groupId) {
    return firestore
        .collection('groups')
        .doc(groupId)
        .collection('chats')
        .orderBy('timeSent')
        .snapshots()
        .map((event) {
      List<Message> messages = [];
      for (var document in event.docs) {
        messages.add(Message.fromMap(document.data()));
      }
      return messages;
    });
  }

  void _saveDataToContactsSubCollection(
    UserModel senderUserData,
    UserModel? receiverUserData,
    String text,
    DateTime timeSent,
    String receiverUserId,
    bool isGroupChat,
  ) async {
    // users => receiver userId => chats => current userId => set data
    var receiverChatContact = ChatContact(
      name: senderUserData.name,
      profilePic: senderUserData.profilePic,
      contactId: senderUserData.uId,
      timeSent: timeSent,
      lastMessage: text,
    );

    if (isGroupChat) {
      await firestore.collection('groups').doc(receiverUserId).update({
        'lastMessage': text,
        'timeSent': DateTime.now().microsecondsSinceEpoch,
      });
    } else {
      await firestore
          .collection('users')
          .doc(receiverUserId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .set(receiverChatContact.toMap());

      // users => current userId => chats => receiver userId => set data
      var senderChatContact = ChatContact(
        name: receiverUserData!.name,
        profilePic: receiverUserData.profilePic,
        contactId: receiverUserData.uId,
        timeSent: timeSent,
        lastMessage: text,
      );

      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverUserId)
          .set(senderChatContact.toMap());
    }
  }

  void _saveMessageToMessageSubCollection({
    required String receiverUserId,
    required String text,
    required DateTime timeSent,
    required String messageId,
    required String username,
    required MessageEnum messageType,
    required MessageReply? messageReply,
    required String? receiverUserName,
    required String senderUsername,
    required bool isGroupChat,
  }) async {
    final message = Message(
      senderId: auth.currentUser!.uid,
      receiverId: receiverUserId,
      text: text,
      type: messageType,
      timeSent: timeSent,
      messageId: messageId,
      isSeen: false,
      repliedMessage: messageReply == null ? '' : messageReply.message,
      repliedTo: messageReply == null
          ? ''
          : messageReply.isMe
              ? senderUsername
              : receiverUserName ?? '',
      repliedMessageType:
          messageReply == null ? MessageEnum.text : messageReply.messageEnum,
    );

    if (isGroupChat) {
      await firestore
          .collection('groups')
          .doc(receiverUserId)
          .collection('chats')
          .doc(messageId)
          .set(message.toMap());
    } else {
      // users => sender id => messages => receiver id => message id => store message
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverUserId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // users => receiver id => messages => sender id => message id => store message
      await firestore
          .collection('users')
          .doc(receiverUserId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());
    }
  }

  void sentTextMessage({
    required BuildContext context,
    required String text,
    required String receiverUserId,
    required UserModel senderUser,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      var timeSent = DateTime.now();
      UserModel? receiverUserData;

      if (!isGroupChat) {
        var userDataMap =
            await firestore.collection('users').doc(receiverUserId).get();
        receiverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      var messageId = const Uuid().v1();

      _saveDataToContactsSubCollection(
        senderUser,
        receiverUserData,
        text,
        timeSent,
        receiverUserId,
        isGroupChat,
      );

      _saveMessageToMessageSubCollection(
        receiverUserId: receiverUserId,
        text: text,
        timeSent: timeSent,
        messageId: messageId,
        username: senderUser.name,
        messageType: MessageEnum.text,
        messageReply: messageReply,
        receiverUserName: receiverUserData?.name,
        senderUsername: senderUser.name,
        isGroupChat: isGroupChat,
      );
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void sendFileMessage({
    required BuildContext context,
    required File file,
    required String receiverUserId,
    required UserModel senderUserData,
    required ProviderRef ref,
    required MessageEnum messageEnum,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      var timeSent = DateTime.now();
      var messageId = const Uuid().v1();

      String imageUrl = await ref
          .read(commonFirebaseStorageRepositoryProvider)
          .storeFileToFirebase(
            'chat/${messageEnum.type}/${senderUserData.uId}/$receiverUserId/$messageId',
            file,
          );

      UserModel? receiverUserData;
      if (!isGroupChat) {
        var userDataMap =
            await firestore.collection('users').doc(receiverUserId).get();
        receiverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      String contactMessage;

      switch (messageEnum) {
        case MessageEnum.image:
          contactMessage = '🖼️Photo';
          break;
        case MessageEnum.video:
          contactMessage = '🖼️Video';
          break;
        case MessageEnum.audio:
          contactMessage = '🎵Audio';
          break;
        case MessageEnum.gif:
          contactMessage = 'GIF';
          break;
        default:
          contactMessage = 'GIF';
      }

      _saveDataToContactsSubCollection(
        senderUserData,
        receiverUserData,
        contactMessage,
        timeSent,
        receiverUserId,
        isGroupChat,
      );

      _saveMessageToMessageSubCollection(
        receiverUserId: receiverUserId,
        text: imageUrl,
        timeSent: timeSent,
        messageId: messageId,
        username: senderUserData.name,
        messageType: messageEnum,
        messageReply: messageReply,
        receiverUserName: receiverUserData?.name,
        senderUsername: senderUserData.name,
        isGroupChat: isGroupChat,
      );
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void sentGIFMessage({
    required BuildContext context,
    required String gifUrl,
    required String receiverUserId,
    required UserModel senderUser,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      var timeSent = DateTime.now();
      UserModel? receiverUserData;
      if (!isGroupChat) {
        var userDataMap =
            await firestore.collection('users').doc(receiverUserId).get();
        receiverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      var messageId = const Uuid().v1();

      _saveDataToContactsSubCollection(
        senderUser,
        receiverUserData,
        'GIF',
        timeSent,
        receiverUserId,
        isGroupChat,
      );

      _saveMessageToMessageSubCollection(
        receiverUserId: receiverUserId,
        text: gifUrl,
        timeSent: timeSent,
        messageId: messageId,
        username: senderUser.name,
        messageType: MessageEnum.gif,
        messageReply: messageReply,
        receiverUserName: receiverUserData?.name,
        senderUsername: senderUser.name,
        isGroupChat: isGroupChat,
      );
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void setChatMessageSeen({
    required BuildContext context,
    required String receiverUserId,
    required String messageId,
  }) async {
    try {
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverUserId)
          .collection('messages')
          .doc(messageId)
          .update({'isSeen': true});

      await firestore
          .collection('users')
          .doc(receiverUserId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .update({'isSeen': true});
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }
}
