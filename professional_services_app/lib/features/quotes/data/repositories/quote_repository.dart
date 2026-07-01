import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/quote_model.dart';

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  return QuoteRepository(
    client: ref.watch(dioProvider),
  );
});

class QuoteRepository {
  QuoteRepository({
    required Dio client,
  }) : _client = client;

  final Dio _client;

  Future<QuoteModel> createQuote(QuoteCreateRequest req) async {
    try {
      final response = await _client.post(
        '/api/v1/quotes/',
        data: req.toJson(),
      );
      return QuoteModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ApiException(
          data is Map ? data['detail']?.toString() ?? 'Error.' : 'Error.',
          statusCode: e.response?.statusCode);
    }
  }

  Future<List<QuoteModel>> getMyQuotes() async {
    try {
      final response = await _client.get('/api/v1/quotes/my-quotes');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map(QuoteModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException('Error al cargar cotizaciones.',
          statusCode: e.response?.statusCode);
    }
  }

  Future<List<QuoteModel>> getReceivedQuotes() async {
    try {
      final response = await _client.get('/api/v1/quotes/received');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map(QuoteModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException('Error al cargar cotizaciones recibidas.',
          statusCode: e.response?.statusCode);
    }
  }

  Future<QuoteModel> respondToQuote(String quoteId, QuoteRespondRequest req) async {
    try {
      final response = await _client.patch(
        '/api/v1/quotes/$quoteId/respond',
        data: req.toJson(),
      );
      return QuoteModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ApiException(
          data is Map ? data['detail']?.toString() ?? 'Error.' : 'Error.',
          statusCode: e.response?.statusCode);
    }
  }
}
