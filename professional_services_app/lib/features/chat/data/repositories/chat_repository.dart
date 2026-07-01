import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final repo = ChatRepository(
    client: ref.watch(dioProvider),
  );
  ref.onDispose(() => repo.dispose());
  return repo;
});

class ChatRepository {
  ChatRepository({
    required Dio client,
  })  : _client = client;

  final Dio _client;
  WebSocketChannel? _wsChannel;
  StreamController<ChatMessageModel>? _wsController;
  bool _wsConnected = false;

  Future<List<ChatInboxItemModel>> getInbox() async {
    try {
      final response = await _client.get('/api/v1/chat/inbox');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => ChatInboxItemModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException('Error al cargar mensajes.', statusCode: e.response?.statusCode);
    }
  }

  Future<List<ChatMessageModel>> getHistory(String contactId) async {
    try {
      final response = await _client.get('/api/v1/chat/history/$contactId');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException('Error al cargar historial.', statusCode: e.response?.statusCode);
    }
  }

  Future<ChatMessageModel> sendMessage(ChatMessageCreateRequest req) async {
    try {
      final response = await _client.post(
        '/api/v1/chat/send',
        data: req.toJson(),
      );
      return ChatMessageModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail']?.toString() : null;
      throw ApiException(detail ?? 'Error al enviar mensaje.', statusCode: e.response?.statusCode);
    }
  }

  Stream<ChatMessageModel> connectWebSocket(String userId, String token) {
    if (_wsConnected && _wsController != null) {
      return _wsController!.stream;
    }

    _wsController?.close();
    _wsController = StreamController<ChatMessageModel>.broadcast();

    // Obtenemos la base URL desde las opciones de Dio y cambiamos el esquema
    final baseUrl = _client.options.baseUrl;
    final wsBase = baseUrl.replaceFirst('http', 'ws');
    final uri = Uri.parse('$wsBase/api/v1/chat/ws/$userId').replace(queryParameters: {'token': token});

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

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _client.get('/api/v1/chat/notifications');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException('Error al cargar notificaciones.', statusCode: e.response?.statusCode);
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _client.patch('/api/v1/chat/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw ApiException('Error al marcar notificación.', statusCode: e.response?.statusCode);
    }
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
