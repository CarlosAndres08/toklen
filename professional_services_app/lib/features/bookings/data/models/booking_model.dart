/// Modelo de Reserva (Booking)
/// Mapea exactamente con el esquema del backend
class BookingModel {
  final String id;
  final String clientId;
  final String serviceId;
  final DateTime? startTime;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? notes;
  final DateTime? createdAt;
  final double? negotiatedPrice;
  
  // Información extraída de los objetos anidados (útil para la UI)
  final String? serviceTitle;
  final double? servicePrice;
  final String? clientName;
  final String? clientEmail;
  final String? providerId;
  final String? providerName;
  final String? providerProfilePicture;

  const BookingModel({
    required this.id,
    required this.clientId,
    required this.serviceId,
    this.startTime,
    required this.status,
    this.notes,
    this.createdAt,
    this.negotiatedPrice,
    this.serviceTitle,
    this.servicePrice,
    this.clientName,
    this.clientEmail,
    this.providerId,
    this.providerName,
    this.providerProfilePicture,
  });

  /// Factory constructor desde JSON del backend
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      serviceId: json['service_id']?.toString() ?? '',
      startTime: _parseDateTime(json['start_time']),
      status: json['status']?.toString() ?? 'pending',
      notes: json['notes']?.toString(),
      createdAt: _parseDateTime(json['created_at']),
      negotiatedPrice: _parseDouble(json['negotiated_price']),
      // Extrayendo datos de los objetos anidados 'service', 'client' y 'provider'
      serviceTitle: json['service']?['title']?.toString(),
      servicePrice: _parseDouble(json['service']?['price']),
      clientName: json['client']?['name']?.toString(),
      clientEmail: json['client']?['email']?.toString(),
      providerId: json['provider']?['id']?.toString(),
      providerName: json['provider']?['name']?.toString(),
      providerProfilePicture: json['provider']?['profile_picture_url']?.toString(),
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'service_id': serviceId,
      if (startTime != null) 'start_time': startTime!.toIso8601String(),
      'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (negotiatedPrice != null) 'negotiated_price': negotiatedPrice,
    };
  }

  /// Helper para parsear DateTime de manera segura
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Helper para parsear double de manera segura
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Obtener color según el estado
  String getStatusColor() {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'success';
      case 'completed':
        return 'primary';
      case 'cancelled':
        return 'error';
      case 'pending':
      default:
        return 'warning';
    }
  }

  /// Obtener texto legible del estado
  String getStatusText() {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmada';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      case 'pending':
      default:
        return 'Pendiente';
    }
  }

  /// Copiar con campos modificados
  BookingModel copyWith({
    String? id,
    String? clientId,
    String? serviceId,
    DateTime? startTime,
    String? status,
    String? notes,
    DateTime? createdAt,
    double? negotiatedPrice,
    String? serviceTitle,
    double? servicePrice,
    String? clientName,
    String? clientEmail,
    String? providerId,
    String? providerName,
    String? providerProfilePicture,
  }) {
    return BookingModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      serviceId: serviceId ?? this.serviceId,
      startTime: startTime ?? this.startTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      negotiatedPrice: negotiatedPrice ?? this.negotiatedPrice,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      servicePrice: servicePrice ?? this.servicePrice,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerProfilePicture: providerProfilePicture ?? this.providerProfilePicture,
    );
  }
}

/// Modelo para crear una nueva reserva (POST /api/v1/bookings/)
class BookingCreateRequest {
  final String serviceId;
  final DateTime startTime;
  final String? notes;

  const BookingCreateRequest({
    required this.serviceId,
    required this.startTime,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'start_time': startTime.toUtc().toIso8601String(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

/// Modelo para actualizar el estado de una reserva (PATCH /api/v1/bookings/{booking_id}/status)
class BookingStatusUpdate {
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'

  const BookingStatusUpdate({
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
    };
  }
}