class UserBasic {
  const UserBasic({
    this.id = '',
    this.nombre = '',
    this.profilePictureUrl,
  });

  final String id;
  final String nombre;
  final String? profilePictureUrl;

  String get name => nombre;

  factory UserBasic.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserBasic();
    return UserBasic(
      id: json['id']?.toString() ?? '',
      nombre: (json['nombre'] ?? json['name'])?.toString() ?? '',
      profilePictureUrl: json['profile_picture_url']?.toString(),
    );
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    this.id = '',
    this.bookingId,
    this.senderId = '',
    this.receiverId = '',
    this.message = '',
    this.isRead = false,
    this.sentAt,
    this.sender,
    this.receiver,
  });

  final String id;
  final String? bookingId;
  final String senderId;
  final String receiverId;
  final String message;
  final bool isRead;
  final DateTime? sentAt;
  final UserBasic? sender;
  final UserBasic? receiver;

  factory ChatMessageModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ChatMessageModel();
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString(),
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == true,
      sentAt: _parseDate(json['sent_at'] ?? json['fecha_envio']),
      sender: json['sender'] != null
          ? UserBasic.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      receiver: json['receiver'] != null
          ? UserBasic.fromJson(json['receiver'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class ChatInboxItemModel {
  const ChatInboxItemModel({
    this.user = const UserBasic(),
    this.lastMessage = '',
    this.lastMessageDate,
    this.unreadCount = 0,
  });

  final UserBasic user;
  final String lastMessage;
  final DateTime? lastMessageDate;
  final int unreadCount;

  factory ChatInboxItemModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ChatInboxItemModel();
    return ChatInboxItemModel(
      user: json['user'] != null
          ? UserBasic.fromJson(json['user'] as Map<String, dynamic>)
          : const UserBasic(),
      lastMessage: json['last_message']?.toString() ?? '',
      lastMessageDate: _parseDate(json['last_message_date']),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class NotificationModel {
  const NotificationModel({
    this.id = '',
    this.title = '',
    this.content = '',
    this.senderId,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final String? senderId;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NotificationModel();
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      senderId: json['sender_id']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: _parseDate(json['created_at'] ?? json['fecha_creacion']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class ChatMessageCreateRequest {
  const ChatMessageCreateRequest({
    required this.receiverId,
    required this.message,
    this.bookingId,
  });

  final String receiverId;
  final String message;
  final String? bookingId;

  Map<String, dynamic> toJson() {
    return {
      'receiver_id': receiverId,
      'message': message,
      if (bookingId != null) 'booking_id': bookingId,
    };
  }
}
