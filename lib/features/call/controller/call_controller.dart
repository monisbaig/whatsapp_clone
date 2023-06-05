import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_clone/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_clone/models/call_model.dart';

import '../repository/call_repository.dart';

final callControllerProvider = Provider((ref) {
  return CallController(
    callRepository: ref.read(callRepositoryProvider),
    auth: FirebaseAuth.instance,
    ref: ref,
  );
});

class CallController {
  final CallRepository callRepository;
  final FirebaseAuth auth;
  final ProviderRef ref;

  CallController({
    required this.callRepository,
    required this.auth,
    required this.ref,
  });

  void makeCall(
    BuildContext context,
    String receiverName,
    String receiverUid,
    String receiverProfilePic,
    bool isGroupChat,
  ) {
    ref.read(userDataAuthProvider).whenData((value) {
      String callId = const Uuid().v1();

      CallModel senderCallData = CallModel(
        callerId: auth.currentUser!.uid,
        callerName: value!.name,
        callerPic: value.profilePic,
        receiverId: receiverUid,
        receiverName: receiverName,
        receiverPic: receiverProfilePic,
        callId: callId,
        hasDialled: true,
      );

      CallModel receiverCallData = CallModel(
        callerId: auth.currentUser!.uid,
        callerName: value.name,
        callerPic: value.profilePic,
        receiverId: receiverUid,
        receiverName: receiverName,
        receiverPic: receiverProfilePic,
        callId: callId,
        hasDialled: false,
      );

      if (isGroupChat) {
        callRepository.makeGroupCall(
          context: context,
          senderCallData: senderCallData,
          receiverCallData: receiverCallData,
        );
      } else {
        callRepository.makeCall(
          context: context,
          senderCallData: senderCallData,
          receiverCallData: receiverCallData,
        );
      }
    });
  }

  void endCall(
    BuildContext context,
    String callerId,
    String receiverId,
  ) {
    callRepository.endCall(
      context: context,
      callerId: callerId,
      receiverId: receiverId,
    );
  }

  Stream<DocumentSnapshot> get callStream => callRepository.callStream;
}
