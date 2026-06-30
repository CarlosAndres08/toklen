import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/quote_model.dart';

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  return QuoteRepository(
    client: ref.watch(httpClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
  );
});

class QuoteRepository {
  QuoteRepository({
    required http.Client client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<QuoteModel> createQuote(String token, QuoteCreateRequest req) async {
    final uri = Uri.parse('$_baseUrl/api/v1/quotes/');
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
      return QuoteModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    throw ApiException(
        data is Map ? data['detail']?.toString() ?? 'Error.' : 'Error.',
        statusCode: response.statusCode);
  }

  Future<List<QuoteModel>> getMyQuotes(String token) async {
    final uri = Uri.parse('$_baseUrl/api/v1/quotes/my-quotes');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(QuoteModel.fromJson)
          .toList();
    }
    throw ApiException('Error al cargar cotizaciones.',
        statusCode: response.statusCode);
  }

  Future<List<QuoteModel>> getReceivedQuotes(String token) async {
    final uri = Uri.parse('$_baseUrl/api/v1/quotes/received');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(QuoteModel.fromJson)
          .toList();
    }
    throw ApiException('Error al cargar cotizaciones recibidas.',
        statusCode: response.statusCode);
  }

  Future<QuoteModel> respondToQuote(
      String token, String quoteId, QuoteRespondRequest req) async {
    final uri = Uri.parse('$_baseUrl/api/v1/quotes/$quoteId/respond');
    final response = await _client.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(req.toJson()),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return QuoteModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    throw ApiException(
        data is Map ? data['detail']?.toString() ?? 'Error.' : 'Error.',
        statusCode: response.statusCode);
  }
}
