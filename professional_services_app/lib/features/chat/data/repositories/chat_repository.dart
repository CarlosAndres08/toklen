import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final repo = ChatRepository(
    client: ref.watch(httpClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
  );
  ref.onDispose(() => repo.dispose());
  return repo;
});

class ChatRepository {
  ChatRepository({
    required http.Client client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;
  WebSocketChannel? _wsChannel;
  StreamController<ChatMessageModel>? _wsController;
  bool _wsConnected = false;

  Future<List<ChatInboxItemModel>> getInbox(String token) async {
    final uri = Uri.parse('$_baseUrl/api/v1/chat/inbox');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body;
      if (body.isEmpty) return [];
      final decoded = jsonDecode(body) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatInboxItemModel.fromJson)
          .toList();
    }

    throw ApiException('Error al cargar mensajes.',
        statusCode: response.statusCode);
  }

  Future<List<ChatMessageModel>> getHistory(
      String token, String contactId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/chat/history/$contactId');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body;
      if (body.isEmpty) return [];
      final decoded = jsonDecode(body) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatMessageModel.fromJson)
          .toList();
    }

    throw ApiException('Error al cargar historial.',
        statusCode: response.statusCode);
  }

  Future<ChatMessageModel> sendMessage(
      String token, ChatMessageCreateRequest req) async {
    final uri = Uri.parse('$_baseUrl/api/v1/chat/send');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(req.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ChatMessageModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    final detail =
        data is Map ? data['detail']?.toString() : null;
    throw ApiException(detail ?? 'Error al enviar mensaje.',
        statusCode: response.statusCode);
  }

  Stream<ChatMessageModel> connectWebSocket(
      String userId, String token) {
    if (_wsConnected && _wsController != null) {
      return _wsController!.stream;
    }

    _wsController?.close();
    _wsController = StreamController<ChatMessageModel>.broadcast();
    final wsBase = _baseUrl.replaceFirst('http', 'ws');
    final uri = Uri.parse('$wsBase/api/v1/chat/ws/$userId')
        .replace(queryParameters: {'token': token});
    _wsChannel = WebSocketChannel.connect(uri);
    _wsConnected = true;

    _wsChannel!.stream.listen(
      (data) {
        final json = jsonDecode(data as String) as Map<String, dynamic>;
        final event = json['event'] as String?;
        if (event == 'new_message') {
          final msgData = json['data'] as Map<String, dynamic>?;
          if (msgData != null) {
            final message = ChatMessageModel.fromJson(msgData);
            _wsController!.add(message);
          }
        }
      },
      onDone: () {
        _wsConnected = false;
      },
      onError: (_) {
        _wsConnected = false;
      },
    );

    return _wsController!.stream;
  }

  Future<List<NotificationModel>> getNotifications(String token) async {
    final uri = Uri.parse('$_baseUrl/api/v1/chat/notifications');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body;
      if (body.isEmpty) return [];
      final decoded = jsonDecode(body) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
    }
    throw ApiException('Error al cargar notificaciones.',
        statusCode: response.statusCode);
  }

  Future<void> markNotificationAsRead(
      String token, String notificationId) async {
    final uri =
        Uri.parse('$_baseUrl/api/v1/chat/notifications/$notificationId/read');
    final response = await _client.patch(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException('Error al marcar notificación.',
        statusCode: response.statusCode);
  }

  void disconnectWebSocket() {
    _wsChannel?.sink.close();
    _wsChannel = null;
    _wsConnected = false;
  }

  void dispose() {
    disconnectWebSocket();
    _wsController?.close();
  }
}
