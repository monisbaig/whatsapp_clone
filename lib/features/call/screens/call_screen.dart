// ignore_for_file: use_build_context_synchronously

import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/config/agora_config.dart';
import 'package:whatsapp_clone/features/call/controller/call_controller.dart';
import 'package:whatsapp_clone/models/call_model.dart';

import '../../../common/widgets/loader.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String channelId;
  final CallModel callModel;
  final bool isGroupChat;

  const CallScreen({
    super.key,
    required this.channelId,
    required this.callModel,
    required this.isGroupChat,
  });

  @override
  ConsumerState createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  AgoraClient? client;
  String baseUrl = '';

  @override
  void initState() {
    super.initState();
    client = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
        appId: AgoraConfig.appId,
        channelName: widget.channelId,
        tokenUrl: baseUrl,
      ),
    );
    initAgora();
  }

  initAgora() async {
    await client!.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: client == null
          ? const Loader()
          : SafeArea(
              child: Stack(
                children: [
                  AgoraVideoViewer(client: client!),
                  AgoraVideoButtons(
                    client: client!,
                    disconnectButtonChild: IconButton(
                      onPressed: () async {
                        await client!.engine.leaveChannel();
                        ref.read(callControllerProvider).endCall(
                              context,
                              widget.callModel.callerId,
                              widget.callModel.receiverId,
                            );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.call_end),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
