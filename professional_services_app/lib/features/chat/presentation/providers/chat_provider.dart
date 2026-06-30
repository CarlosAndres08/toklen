import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/chat_repository.dart';

final inboxProvider = FutureProvider<List<ChatInboxItemModel>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final token = authState.value?.accessToken ?? '';
  if (token.isEmpty) return [];
  return ref.read(chatRepositoryProvider).getInbox(token);
});

final chatHistoryProvider =
    FutureProvider.family<List<ChatMessageModel>, String>((ref, contactId) {
  final authState = ref.watch(authControllerProvider);
  final token = authState.value?.accessToken ?? '';
  if (token.isEmpty) return [];
  return ref.read(chatRepositoryProvider).getHistory(token, contactId);
});

final loadInboxProvider = Provider<void Function()>((ref) {
  return () => ref.invalidate(inboxProvider);
});

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final token = authState.value?.accessToken ?? '';
  if (token.isEmpty) return [];
  return ref.read(chatRepositoryProvider).getNotifications(token);
});

class SendMessageState {
  final bool isLoading;
  final String? error;
  final ChatMessageModel? message;

  const SendMessageState({
    this.isLoading = false,
    this.error,
    this.message,
  });

  SendMessageState copyWith({
    bool? isLoading,
    String? error,
    ChatMessageModel? message,
  }) {
    return SendMessageState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      message: message ?? this.message,
    );
  }
}

class SendMessageNotifier extends Notifier<SendMessageState> {
  @override
  SendMessageState build() => const SendMessageState();

  Future<void> send({
    required String receiverId,
    required String message,
    String? bookingId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token =
          ref.read(authControllerProvider).value?.accessToken ?? '';
      if (token.isEmpty) throw Exception('No autenticado.');
      final req = ChatMessageCreateRequest(
        receiverId: receiverId,
        message: message,
        bookingId: bookingId,
      );
      final msg =
          await ref.read(chatRepositoryProvider).sendMessage(token, req);
      state = state.copyWith(isLoading: false, message: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const SendMessageState();
}

final sendMessageControllerProvider =
    NotifierProvider<SendMessageNotifier, SendMessageState>(
        SendMessageNotifier.new);

final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.read(authControllerProvider).value?.user;
  return user?.id;
});

final wsMessagesProvider =
    StreamProvider.family<ChatMessageModel, String>((ref, contactId) {
  final chatRepo = ref.read(chatRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  final authState = ref.watch(authControllerProvider);
  final token = authState.value?.accessToken;
  if (userId == null || token == null || token.isEmpty) {
    return const Stream.empty();
  }
  final stream = chatRepo.connectWebSocket(userId, token);
  ref.onDispose(() {});
  return stream.where((msg) =>
      msg.senderId == contactId || msg.receiverId == contactId);
});
