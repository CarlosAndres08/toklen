import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(
    client: ref.watch(dioProvider),
  );
});

class FavoriteRepository {
  FavoriteRepository({required Dio client})
      : _client = client;

  final Dio _client;

  Future<bool> addFavorite(String serviceId) async {
    try {
      final response = await _client.post('/api/v1/favorites/$serviceId');
      if (response.statusCode == 201) return true;
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) return false;
      throw ApiException('Error al agregar favorito.', statusCode: e.response?.statusCode);
    }
  }

  Future<bool> removeFavorite(String serviceId) async {
    try {
      final response = await _client.delete('/api/v1/favorites/$serviceId');
      if (response.statusCode == 204) return true;
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      throw ApiException('Error al eliminar favorito.', statusCode: e.response?.statusCode);
    }
  }

  Future<List<String>> listFavoriteIds() async {
    try {
      final response = await _client.get('/api/v1/favorites/');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => e['service_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ApiException('Error al cargar favoritos.', statusCode: e.response?.statusCode);
    }
  }
}
