// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/common/utils/utils.dart';
import 'package:whatsapp_clone/features/call/screens/call_screen.dart';
import 'package:whatsapp_clone/models/call_model.dart';
import 'package:whatsapp_clone/models/group_model.dart';

final callRepositoryProvider = Provider((ref) {
  return CallRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class CallRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CallRepository({
    required this.firestore,
    required this.auth,
  });

  void makeCall({
    required BuildContext context,
    required CallModel senderCallData,
    required CallModel receiverCallData,
  }) async {
    try {
      await firestore
          .collection('call')
          .doc(senderCallData.callerId)
          .set(senderCallData.toMap());
      await firestore
          .collection('call')
          .doc(senderCallData.receiverId)
          .set(receiverCallData.toMap());

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            channelId: senderCallData.callId,
            callModel: senderCallData,
            isGroupChat: false,
          ),
        ),
      );
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void makeGroupCall({
    required BuildContext context,
    required CallModel senderCallData,
    required CallModel receiverCallData,
  }) async {
    try {
      await firestore
          .collection('call')
          .doc(senderCallData.callerId)
          .set(senderCallData.toMap());

      var groupSnapshot = await firestore
          .collection('groups')
          .doc(senderCallData.receiverId)
          .get();

      GroupModel groupModel = GroupModel.fromMap(groupSnapshot.data()!);

      for (var id in groupModel.membersUid) {
        await firestore
            .collection('call')
            .doc(id)
            .set(receiverCallData.toMap());
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            channelId: senderCallData.callId,
            callModel: senderCallData,
            isGroupChat: true,
          ),
        ),
      );
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void endCall({
    required BuildContext context,
    required String callerId,
    required String receiverId,
  }) async {
    try {
      await firestore.collection('call').doc(callerId).delete();

      await firestore.collection('call').doc(receiverId).delete();
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void endGroupCall({
    required BuildContext context,
    required String callerId,
    required String receiverId,
  }) async {
    try {
      await firestore.collection('call').doc(callerId).delete();

      var groupSnapshot =
          await firestore.collection('groups').doc(receiverId).get();

      GroupModel groupModel = GroupModel.fromMap(groupSnapshot.data()!);

      for (var id in groupModel.membersUid) {
        await firestore.collection('call').doc(id).delete();
      }
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Stream<DocumentSnapshot> get callStream =>
      firestore.collection('call').doc(auth.currentUser!.uid).snapshots();
}
