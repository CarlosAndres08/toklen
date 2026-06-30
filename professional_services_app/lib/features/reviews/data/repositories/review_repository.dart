import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_exception.dart';
import '../models/review_model.dart';

class ReviewRepository {
  const ReviewRepository({
    required http.Client client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<List<ReviewModel>> getServiceReviews(String serviceId) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/reviews/service/$serviceId');

    final http.Response response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final bodyString = response.body;
      if (bodyString.isEmpty) return [];
      final decoded = jsonDecode(bodyString) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ReviewModel.fromJson)
          .toList();
    }

    throw ApiException('Error al cargar reseñas.', statusCode: response.statusCode);
  }

  Future<ReviewModel> createReview({
    required String token,
    required ReviewCreateRequest request,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/reviews/');

    final http.Response response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ReviewModel.fromJson(data);
    }

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    final detail = body is Map ? body['detail']?.toString() : null;
    throw ApiException(
      detail ?? 'Error al crear la reseña.',
      statusCode: response.statusCode,
    );
  }
}
