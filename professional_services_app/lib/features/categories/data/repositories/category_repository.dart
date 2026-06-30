import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_exception.dart';
import '../models/category_model.dart';

class CategoryRepository {
  const CategoryRepository({
    required http.Client client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<List<CategoryModel>> getCategories() async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/categories/');

    final http.Response response = await _client.get(
      uri,
      headers: const <String, String>{
        'Accept': 'application/json',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final String bodyString = response.body;
      if (bodyString.isEmpty) {
        return <CategoryModel>[];
      }

      final Object? decodedBody = jsonDecode(bodyString);
      
      if (decodedBody is List<dynamic>) {
        return decodedBody
            .whereType<Map<String, dynamic>>()
            .map(CategoryModel.fromJson)
            .toList();
      }
      return <CategoryModel>[];
    }

    throw ApiException(
      'Error al cargar las categorías',
      statusCode: response.statusCode,
    );
  }
}