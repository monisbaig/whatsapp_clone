import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_clone/features/status/repository/status_repository.dart';
import 'package:whatsapp_clone/models/status_model.dart';

final statusControllerProvider = Provider((ref) {
  return StatusController(
    statusRepository: ref.read(statusRepositoryProvider),
    ref: ref,
  );
});

class StatusController {
  final StatusRepository statusRepository;
  final ProviderRef ref;

  StatusController({
    required this.statusRepository,
    required this.ref,
  });

  void uploadStatus(
    BuildContext context,
    File file,
  ) {
    ref.watch(userDataAuthProvider).whenData((value) {
      return statusRepository.uploadStatus(
        context: context,
        username: value!.name,
        profilePic: value.profilePic,
        phoneNumber: value.phoneNumber,
        statusImage: file,
      );
    });
  }

  Future<List<Status>> getStatus(BuildContext context) async {
    List<Status> statuses = await statusRepository.getStatus(context: context);
    return statuses;
  }
}
