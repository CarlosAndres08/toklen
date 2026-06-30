import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(
    client: ref.watch(httpClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
  );
});

class FavoriteRepository {
  FavoriteRepository({required http.Client client, required String baseUrl})
      : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<bool> addFavorite(String token, String serviceId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/favorites/$serviceId');
    final response = await _client.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 201) return true;
    if (response.statusCode == 409) return false;
    throw ApiException('Error al agregar favorito.',
        statusCode: response.statusCode);
  }

  Future<bool> removeFavorite(String token, String serviceId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/favorites/$serviceId');
    final response = await _client.delete(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 204) return true;
    if (response.statusCode == 404) return false;
    throw ApiException('Error al eliminar favorito.',
        statusCode: response.statusCode);
  }

  Future<List<String>> listFavoriteIds(String token) async {
    final uri = Uri.parse('$_baseUrl/api/v1/favorites/');
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
          .map((e) => e['service_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    }
    throw ApiException('Error al cargar favoritos.',
        statusCode: response.statusCode);
  }
}
