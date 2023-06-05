import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_clone/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapp_clone/common/utils/utils.dart';
import 'package:whatsapp_clone/models/user_model.dart';

import '../../../models/status_model.dart';

final statusRepositoryProvider = Provider((ref) {
  return StatusRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    ref: ref,
  );
});

class StatusRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final ProviderRef ref;

  StatusRepository({
    required this.firestore,
    required this.auth,
    required this.ref,
  });

  void uploadStatus({
    required BuildContext context,
    required String username,
    required String profilePic,
    required String phoneNumber,
    required File statusImage,
  }) async {
    try {
      var statusId = const Uuid().v1();
      String uId = auth.currentUser!.uid;
      String imageUrl = await ref
          .read(commonFirebaseStorageRepositoryProvider)
          .storeFileToFirebase(
            '/status/$statusId$uId',
            statusImage,
          );
      List<Contact> contacts = [];
      if (await FlutterContacts.requestPermission()) {
        contacts = await FlutterContacts.getContacts(withProperties: true);
      }

      List<String> uIdWhoCanSee = [];

      for (int i = 0; i < contacts.length; i++) {
        var userContactData = await firestore
            .collection('users')
            .where(
              'phoneNumber',
              isEqualTo: contacts[i].phones[0].number.replaceAll(
                    ' ',
                    '',
                  ),
            )
            .get();
        if (userContactData.docs.isNotEmpty) {
          var userData = UserModel.fromMap(userContactData.docs[0].data());
          uIdWhoCanSee.add(userData.uId);
        }
      }

      List<String> statusImageUrls = [];
      var statusSnapshot = await firestore
          .collection('status')
          .where(
            'uId',
            isEqualTo: auth.currentUser!.uid,
          )
          .get();

      if (statusSnapshot.docs.isNotEmpty) {
        Status status = Status.fromMap(
          statusSnapshot.docs[0].data(),
        );
        statusImageUrls = status.photoUrl;
        statusImageUrls.add(imageUrl);

        await firestore
            .collection('status')
            .doc(statusSnapshot.docs[0].id)
            .update({
          'photoUrl': statusImageUrls,
        });
        return;
      } else {
        statusImageUrls = [imageUrl];
      }

      Status status = Status(
        uId: uId,
        username: username,
        phoneNumber: phoneNumber,
        photoUrl: statusImageUrls,
        createdAt: DateTime.now(),
        profilePic: profilePic,
        statusId: statusId,
        whoCanSee: uIdWhoCanSee,
      );

      await firestore.collection('status').doc(statusId).set(status.toMap());
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Future<List<Status>> getStatus({required BuildContext context}) async {
    List<Status> statusData = [];
    try {
      List<Contact> contacts = [];
      if (await FlutterContacts.requestPermission()) {
        contacts = await FlutterContacts.getContacts(withProperties: true);
      }

      for (int i = 0; i < contacts.length; i++) {
        var statusSnapshot = await firestore
            .collection('status')
            .where(
              'phoneNumber',
              isEqualTo: contacts[i].phones[0].number.replaceAll(
                    ' ',
                    '',
                  ),
            )
            .where(
              'createdAt',
              isGreaterThan: DateTime.now()
                  .subtract(
                    const Duration(hours: 24),
                  )
                  .millisecondsSinceEpoch,
            )
            .get();
        for (var tempData in statusSnapshot.docs) {
          Status tempStatus = Status.fromMap(tempData.data());
          if (tempStatus.whoCanSee.contains(auth.currentUser!.uid)) {
            statusData.add(tempStatus);
          }
        }
      }
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
    return statusData;
  }
}
