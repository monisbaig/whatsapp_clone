import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/features/group/repository/group_repository.dart';

final groupControllerProvider = Provider((ref) {
  return GroupController(
    groupRepository: ref.read(groupRepositoryProvider),
    ref: ref,
  );
});

class GroupController {
  final CallRepository groupRepository;
  final ProviderRef ref;

  GroupController({
    required this.groupRepository,
    required this.ref,
  });

  void createGroup(
    BuildContext context,
    String name,
    File profilePic,
    List<Contact> selectedContact,
  ) {
    groupRepository.createGroup(
      context: context,
      name: name,
      profilePic: profilePic,
      selectedContact: selectedContact,
    );
  }
}
