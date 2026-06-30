import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final serviceManagementRepositoryProvider =
    Provider<ServiceManagementRepository>((ref) {
  return ServiceManagementRepository(
    client: ref.watch(httpClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
    ref: ref,
  );
});

class ServiceManagementRepository {
  ServiceManagementRepository({
    required http.Client client,
    required String baseUrl,
    required Ref ref,
  })  : _client = client,
        _baseUrl = baseUrl,
        _ref = ref;

  final http.Client _client;
  final String _baseUrl;
  final Ref _ref;

  Future<List<dynamic>> listServices() async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/services');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw ApiException('Error al cargar servicios',
        statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> getServiceDetail(String serviceId) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/services/$serviceId');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Error al cargar detalle del servicio',
        statusCode: response.statusCode);
  }

  Future<bool> updateService(
      String serviceId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/services/$serviceId');
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
    throw ApiException('Error al actualizar servicio',
        statusCode: response.statusCode);
  }

  Future<bool> deleteService(String serviceId) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/services/$serviceId');
    final response = await _client.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw ApiException('Error al eliminar servicio',
        statusCode: response.statusCode);
  }

  Future<bool> approveService(String serviceId) async {
    final token = await _getToken();
    final uri =
        Uri.parse('$_baseUrl/api/v1/admin/services/$serviceId/approve');
    final response = await _client.post(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw ApiException('Error al aprobar servicio',
        statusCode: response.statusCode);
  }

  Future<bool> rejectService(
      String serviceId, String reason) async {
    final token = await _getToken();
    final uri =
        Uri.parse('$_baseUrl/api/v1/admin/services/$serviceId/reject');
    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw ApiException('Error al rechazar servicio',
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
