import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';

final categoryManagementRepositoryProvider =
    Provider<CategoryManagementRepository>((ref) {
  return CategoryManagementRepository(
    client: ref.watch(dioProvider),
  );
});

class CategoryManagementRepository {
  CategoryManagementRepository({
    required Dio client,
  }) : _client = client;

  final Dio _client;

  Future<List<dynamic>> getAllCategories() async {
    try {
      final response = await _client.get('/api/v1/admin/categories');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException('Error al cargar categorías',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> createCategory(Map<String, dynamic> data) async {
    try {
      await _client.post(
        '/api/v1/admin/categories',
        data: data,
      );
      return true;
    } on DioException catch (e) {
      final body = e.response?.data;
      throw ApiException(
          body is Map ? body['detail']?.toString() ?? 'Error al crear categoría' : 'Error al crear categoría',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> updateCategory(
      String categoryId, Map<String, dynamic> data) async {
    try {
      await _client.put(
        '/api/v1/admin/categories/$categoryId',
        data: data,
      );
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al actualizar categoría',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _client.delete('/api/v1/admin/categories/$categoryId');
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al eliminar categoría',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> uploadCategoryImage(
      String categoryId, String imageUrl) async {
    try {
      await _client.post(
        '/api/v1/admin/categories/$categoryId/image',
        data: {'image': imageUrl},
      );
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al subir imagen de categoría',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> reorderCategories(List<Map<String, dynamic>> order) async {
    try {
      await _client.put(
        '/api/v1/admin/categories/reorder',
        data: order, // El backend espera una lista directamente según admin.py: reorder_categories(items: List[CategoryReorderItem])
      );
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al reordenar categorías',
          statusCode: e.response?.statusCode);
    }
  }
}
