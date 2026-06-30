import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String contactId;
  final String contactName;

  const ChatRoomScreen({
    super.key,
    required this.contactId,
    required this.contactName,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(chatHistoryProvider(widget.contactId));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(chatHistoryProvider(widget.contactId));
    final sendState = ref.watch(sendMessageControllerProvider);

    ref.listen(sendMessageControllerProvider, (prev, next) {
      final error = next.error;
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    ref.listen(wsMessagesProvider(widget.contactId), (prev, next) {
      next.whenData((_) {
        ref.invalidate(chatHistoryProvider(widget.contactId));
      });
    });

    ref.listen(chatHistoryProvider(widget.contactId), (_, next) {
      next.whenData((_) => ref.invalidate(inboxProvider));
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contactName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: historyAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay mensajes aun. Envia el primero!',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }
                final userId = ref.read(currentUserIdProvider);
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isOwn = msg.senderId == userId;
                    return ChatBubble(message: msg, isOwn: isOwn);
                  },
                );
              },
            ),
          ),
          ChatInput(
            isLoading: sendState.isLoading,
            onSend: (text) {
              ref.read(sendMessageControllerProvider.notifier).send(
                    receiverId: widget.contactId,
                    message: text,
                  );
            },
          ),
        ],
      ),
    );
  }
}
