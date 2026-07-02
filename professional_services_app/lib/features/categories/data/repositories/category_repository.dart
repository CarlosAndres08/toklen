import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../models/category_model.dart';

class CategoryRepository {
  const CategoryRepository({
    required Dio client,
  }) : _client = client;

  final Dio _client;

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _client.get('/api/v1/categories/');

      final List<dynamic> data = response.data as List<dynamic>;
      return data.whereType<Map<String, dynamic>>().map(CategoryModel.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException(
        'Error al cargar las categorías',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
