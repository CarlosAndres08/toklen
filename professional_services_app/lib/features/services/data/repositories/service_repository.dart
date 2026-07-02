import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../models/service_model.dart';
import '../models/provider_profile_model.dart';

class ServiceRepository {
  const ServiceRepository({
    required Dio client,
  }) : _client = client;

  final Dio _client;

  Future<bool> toggleAvailability() async {
    try {
      await _client.put('/api/v1/users/me/availability');
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al cambiar disponibilidad.', statusCode: e.response?.statusCode);
    }
  }

  Future<ProviderProfileModel> getProviderProfile({
    required String providerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.get(
        '/api/v1/users/$providerId/profile',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return ProviderProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException('Error al cargar perfil del proveedor.', statusCode: e.response?.statusCode);
    }
  }

  Future<List<ServiceModel>> getServices({
    String? categoryId,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? lat,
    double? lng,
    double? radius,
    String? sortBy,
    bool? featured,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (categoryId != null && categoryId.isNotEmpty) queryParameters['category_id'] = categoryId;
      if (searchQuery != null && searchQuery.isNotEmpty) queryParameters['q'] = searchQuery;
      if (minPrice != null) queryParameters['min_price'] = minPrice;
      if (maxPrice != null) queryParameters['max_price'] = maxPrice;
      if (minRating != null) queryParameters['min_rating'] = minRating;
      if (lat != null) queryParameters['lat'] = lat;
      if (lng != null) queryParameters['lng'] = lng;
      if (radius != null) queryParameters['radius'] = radius;
      if (sortBy != null) queryParameters['sort_by'] = sortBy;
      if (featured != null) queryParameters['featured'] = featured;

      final response = await _client.get(
        '/api/v1/services/',
        queryParameters: queryParameters,
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.whereType<Map<String, dynamic>>().map(ServiceModel.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException('Error al cargar el catálogo.', statusCode: e.response?.statusCode);
    }
  }

  Future<ServiceModel> getServiceById({required String serviceId}) async {
    try {
      final response = await _client.get('/api/v1/services/$serviceId');
      return ServiceModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException('Error al cargar el detalle del servicio.', statusCode: e.response?.statusCode);
    }
  }

  Future<ServiceModel> createService({required ServiceCreateRequest request}) async {
    try {
      final response = await _client.post(
        '/api/v1/services/',
        data: request.toJson(),
      );
      return ServiceModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_extractErrorMessage(e.response?.data), statusCode: e.response?.statusCode);
    }
  }

  Future<ServiceModel> updateService({
    required String serviceId,
    required ServiceUpdateRequest request,
  }) async {
    try {
      final response = await _client.put(
        '/api/v1/services/$serviceId',
        data: request.toJson(),
      );
      return ServiceModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_extractErrorMessage(e.response?.data), statusCode: e.response?.statusCode);
    }
  }

  Future<bool> deleteService({required String serviceId}) async {
    try {
      await _client.delete('/api/v1/services/$serviceId');
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al eliminar el servicio.', statusCode: e.response?.statusCode);
    }
  }

  Future<bool> uploadServiceImage({
    required String serviceId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'files': [
          MultipartFile.fromBytes(imageBytes, filename: fileName),
        ],
      });

      await _client.post(
        '/api/v1/services/$serviceId/gallery',
        data: formData,
      );
      return true;
    } on DioException catch (e) {
      throw ApiException(_extractErrorMessage(e.response?.data), statusCode: e.response?.statusCode);
    }
  }

  Future<bool> deleteServiceImage({
    required String serviceId,
    required String imageId,
  }) async {
    try {
      await _client.delete('/api/v1/services/$serviceId/gallery/$imageId');
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al eliminar la imagen.', statusCode: e.response?.statusCode);
    }
  }

  String _extractErrorMessage(Object? body) {
    if (body is Map<String, dynamic>) {
      final Object? detail = body['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List<dynamic> && detail.isNotEmpty) {
        final Object? first = detail.first;
        if (first is Map<String, dynamic>) return first['msg']?.toString() ?? 'Error.';
      }
    }
    return 'Error al procesar la solicitud.';
  }
}
