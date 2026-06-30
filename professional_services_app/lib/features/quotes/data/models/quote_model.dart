class QuoteModel {
  const QuoteModel({
    this.id = '',
    this.serviceId = '',
    this.clientId = '',
    this.description = '',
    this.proposedPrice,
    this.status = 'requested',
    this.bookingId,
    this.createdAt,
  });

  final String id;
  final String serviceId;
  final String clientId;
  final String description;
  final double? proposedPrice;
  final String status;
  final String? bookingId;
  final DateTime? createdAt;

  factory QuoteModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const QuoteModel();
    return QuoteModel(
      id: json['id']?.toString() ?? '',
      serviceId: json['service_id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      proposedPrice: (json['proposed_price'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'requested',
      bookingId: json['booking_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

class QuoteCreateRequest {
  const QuoteCreateRequest({
    required this.serviceId,
    required this.description,
  });

  final String serviceId;
  final String description;

  Map<String, dynamic> toJson() => {
        'service_id': serviceId,
        'description': description,
      };
}

class QuoteRespondRequest {
  const QuoteRespondRequest({
    this.status,
    this.proposedPrice,
    this.startTime,
  });

  final String? status;
  final double? proposedPrice;
  final DateTime? startTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (status != null) map['status'] = status;
    if (proposedPrice != null) map['proposed_price'] = proposedPrice;
    if (startTime != null) map['start_time'] = startTime!.toUtc().toIso8601String();
    return map;
  }
}
