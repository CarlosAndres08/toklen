import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final categoryManagementRepositoryProvider =
    Provider<CategoryManagementRepository>((ref) {
  return CategoryManagementRepository(
    client: ref.watch(httpClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
    ref: ref,
  );
});

class CategoryManagementRepository {
  CategoryManagementRepository({
    required http.Client client,
    required String baseUrl,
    required Ref ref,
  })  : _client = client,
        _baseUrl = baseUrl,
        _ref = ref;

  final http.Client _client;
  final String _baseUrl;
  final Ref _ref;

  Future<List<dynamic>> getAllCategories() async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/categories');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw ApiException('Error al cargar categorías',
        statusCode: response.statusCode);
  }

  Future<bool> createCategory(Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/categories');
    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    final body = jsonDecode(response.body);
    throw ApiException(
        body['detail']?.toString() ?? 'Error al crear categoría',
        statusCode: response.statusCode);
  }

  Future<bool> updateCategory(
      String categoryId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/categories/$categoryId');
    final response = await _client.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw ApiException('Error al actualizar categoría',
        statusCode: response.statusCode);
  }

  Future<bool> deleteCategory(String categoryId) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/categories/$categoryId');
    final response = await _client.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw ApiException('Error al eliminar categoría',
        statusCode: response.statusCode);
  }

  Future<bool> uploadCategoryImage(
      String categoryId, String imageUrl) async {
    final token = await _getToken();
    final uri =
        Uri.parse('$_baseUrl/api/v1/admin/categories/$categoryId/image');
    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'image': imageUrl}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw ApiException('Error al subir imagen de categoría',
        statusCode: response.statusCode);
  }

  Future<bool> reorderCategories(List<Map<String, dynamic>> order) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/categories/reorder');
    final response = await _client.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'categories': order}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw ApiException('Error al reordenar categorías',
        statusCode: response.statusCode);
  }

  Future<String> _getToken() async {
    final token = _ref.read(authControllerProvider).value?.accessToken;
    if (token == null || token.isEmpty) {
      throw ApiException('No hay sesión activa');
    }
    return token;
  }
}
