import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_exception.dart';
import '../models/service_model.dart';
import '../models/provider_profile_model.dart';

class ServiceRepository {
  const ServiceRepository({
    required http.Client client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// Listar y buscar servicios - GET /api/v1/services/
  Future<bool> toggleAvailability({required String token}) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/users/me/availability');
    final http.Response response = await _client.put(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return true;
    throw ApiException('Error al cambiar disponibilidad.', statusCode: response.statusCode);
  }

  Future<ProviderProfileModel> getProviderProfile({
    required String providerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/users/$providerId/profile')
        .replace(queryParameters: {'page': page.toString(), 'page_size': pageSize.toString()});
    final http.Response response = await _client.get(uri, headers: const {'Accept': 'application/json'});
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ProviderProfileModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw ApiException('Error al cargar perfil del proveedor.', statusCode: response.statusCode);
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
    final Map<String, String> queryParameters = <String, String>{};
    if (categoryId != null && categoryId.isNotEmpty) queryParameters['category_id'] = categoryId;
    if (searchQuery != null && searchQuery.isNotEmpty) queryParameters['q'] = searchQuery;
    if (minPrice != null) queryParameters['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParameters['max_price'] = maxPrice.toString();
    if (minRating != null) queryParameters['min_rating'] = minRating.toString();
    if (lat != null) queryParameters['lat'] = lat.toString();
    if (lng != null) queryParameters['lng'] = lng.toString();
    if (radius != null) queryParameters['radius'] = radius.toString();
    if (sortBy != null) queryParameters['sort_by'] = sortBy;
    if (featured != null) queryParameters['featured'] = featured.toString();

    final Uri uri = Uri.parse('$_baseUrl/api/v1/services/').replace(queryParameters: queryParameters);

    final http.Response response = await _client.get(uri, headers: const {'Accept': 'application/json'});

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final String bodyString = response.body;
      if (bodyString.isEmpty) return <ServiceModel>[];
      final Object? decodedBody = jsonDecode(bodyString);
      if (decodedBody is List<dynamic>) {
        return decodedBody.whereType<Map<String, dynamic>>().map(ServiceModel.fromJson).toList();
      }
      return <ServiceModel>[];
    }
    throw ApiException('Error al cargar el catálogo.', statusCode: response.statusCode);
  }

  /// Obtener detalle de un servicio - GET /api/v1/services/{service_id}
  Future<ServiceModel> getServiceById({
    required String serviceId,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/services/$serviceId');

    final http.Response response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ServiceModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw ApiException('Error al cargar el detalle del servicio.', statusCode: response.statusCode);
  }

  /// Crear servicio - POST /api/v1/services/
  Future<ServiceModel> createService({
    required String token,
    required ServiceCreateRequest request,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/services/');
    
    final http.Response response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(request.toJson()),
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ServiceModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw ApiException(_extractErrorMessage(jsonDecode(response.body)), statusCode: response.statusCode);
  }

  /// Editar servicio - PUT /api/v1/services/{service_id}
  Future<ServiceModel> updateService({
    required String token,
    required String serviceId,
    required ServiceUpdateRequest request,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/services/$serviceId');
    
    final http.Response response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(request.toJson()),
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ServiceModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw ApiException(_extractErrorMessage(jsonDecode(response.body)), statusCode: response.statusCode);
  }

  /// Eliminar servicio - DELETE /api/v1/services/{service_id}
  Future<bool> deleteService({
    required String token,
    required String serviceId,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/services/$serviceId');
    
    final http.Response response = await _client.delete(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) return true;
    throw ApiException('Error al eliminar el servicio.', statusCode: response.statusCode);
  }

  /// Subir imagen a la galería - POST /api/v1/services/{service_id}/gallery
  Future<bool> uploadServiceImage({
    required String token,
    required String serviceId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/services/$serviceId/gallery'); 
    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json';

    request.files.add(http.MultipartFile.fromBytes('files', imageBytes, filename: fileName));

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) return true;
    throw ApiException(_extractErrorMessage(jsonDecode(response.body)), statusCode: response.statusCode);
  }

  /// Borrar imagen específica de la galería - DELETE /api/v1/services/{service_id}/gallery/{image_id}
  Future<bool> deleteServiceImage({
    required String token,
    required String serviceId,
    required String imageId,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/services/$serviceId/gallery/$imageId');
    final http.Response response = await _client.delete(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return true;
    throw ApiException('Error al eliminar la imagen.', statusCode: response.statusCode);
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