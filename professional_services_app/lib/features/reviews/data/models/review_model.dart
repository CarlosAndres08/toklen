class ReviewClientModel {
  const ReviewClientModel({
    this.id = '',
    this.name = '',
    this.email = '',
  });

  final String id;
  final String name;
  final String email;

  factory ReviewClientModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReviewClientModel();
    return ReviewClientModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class ReviewBookingModel {
  const ReviewBookingModel({
    this.id = '',
    this.startTime,
    this.status = '',
    this.client,
  });

  final String id;
  final DateTime? startTime;
  final String status;
  final ReviewClientModel? client;

  factory ReviewBookingModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReviewBookingModel();
    return ReviewBookingModel(
      id: json['id']?.toString() ?? '',
      startTime: json['start_time'] != null ? DateTime.tryParse(json['start_time']) : null,
      status: json['status']?.toString() ?? '',
      client: json['client'] != null
          ? ReviewClientModel.fromJson(json['client'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ReviewModel {
  const ReviewModel({
    this.id = '',
    this.bookingId = '',
    this.rating = 0,
    this.comment,
    this.createdAt,
    this.booking,
  });

  final String id;
  final String bookingId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final ReviewBookingModel? booking;

  String get clientName => booking?.client?.name ?? 'Anónimo';

  factory ReviewModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReviewModel();
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      booking: json['booking'] != null
          ? ReviewBookingModel.fromJson(json['booking'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ReviewCreateRequest {
  const ReviewCreateRequest({
    required this.bookingId,
    required this.rating,
    this.comment,
  });

  final String bookingId;
  final int rating;
  final String? comment;

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }
}
