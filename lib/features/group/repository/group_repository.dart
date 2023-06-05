import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_clone/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapp_clone/common/utils/utils.dart';
import 'package:whatsapp_clone/models/group_model.dart';

final groupRepositoryProvider = Provider((ref) {
  return CallRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    ref: ref,
  );
});

class CallRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final ProviderRef ref;

  CallRepository({
    required this.firestore,
    required this.auth,
    required this.ref,
  });

  void createGroup({
    required BuildContext context,
    required String name,
    required File profilePic,
    required List<Contact> selectedContact,
  }) async {
    try {
      List<String> uIds = [];
      for (int i = 0; i < selectedContact.length; i++) {
        var userCollection = await firestore
            .collection('users')
            .where(
              'phoneNumber',
              isEqualTo: selectedContact[i].phones[0].number.replaceAll(
                    ' ',
                    '',
                  ),
            )
            .get();

        if (userCollection.docs.isNotEmpty && userCollection.docs[0].exists) {
          uIds.add(userCollection.docs[0].data()['uId']);
        }
      }
      var groupId = const Uuid().v1();

      String groupPicUrl = await ref
          .read(commonFirebaseStorageRepositoryProvider)
          .storeFileToFirebase(
            'group/$groupId',
            profilePic,
          );

      GroupModel groupModel = GroupModel(
        senderId: auth.currentUser!.uid,
        name: name,
        groupId: groupId,
        lastMessage: '',
        groupPic: groupPicUrl,
        membersUid: [auth.currentUser!.uid, ...uIds],
        timeSent: DateTime.now(),
      );

      await firestore.collection('groups').doc(groupId).set(groupModel.toMap());
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }
}
