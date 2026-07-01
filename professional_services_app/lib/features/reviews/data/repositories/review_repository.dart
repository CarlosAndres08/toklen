import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../models/review_model.dart';

class ReviewRepository {
  const ReviewRepository({
    required Dio client,
  }) : _client = client;

  final Dio _client;

  Future<List<ReviewModel>> getServiceReviews(String serviceId) async {
    try {
      final response = await _client.get('/api/v1/reviews/service/$serviceId');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map(ReviewModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException('Error al cargar reseñas.', statusCode: e.response?.statusCode);
    }
  }

  Future<ReviewModel> createReview({
    required ReviewCreateRequest request,
  }) async {
    try {
      final response = await _client.post(
        '/api/v1/reviews/',
        data: request.toJson(),
      );
      return ReviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final body = e.response?.data;
      final detail = body is Map ? body['detail']?.toString() : null;
      throw ApiException(
        detail ?? 'Error al crear la reseña.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
