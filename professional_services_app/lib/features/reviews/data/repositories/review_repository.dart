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

  Future<ReviewModel> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _client.put(
        '/api/v1/reviews/$reviewId',
        data: {
          'rating': rating,
          'comment': comment,
        },
      );
      return ReviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final body = e.response?.data;
      final detail = body is Map ? body['detail']?.toString() : null;
      throw ApiException(
        detail ?? 'Error al actualizar la reseña.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await _client.delete('/api/v1/reviews/$reviewId');
    } on DioException catch (e) {
      throw ApiException('Error al eliminar la reseña.',
          statusCode: e.response?.statusCode);
    }
  }
}
