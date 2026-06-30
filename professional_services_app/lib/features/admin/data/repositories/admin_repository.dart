import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(
    client: ref.watch(httpClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
    ref: ref,
  );
});

class AdminRepository {
  AdminRepository({
    required http.Client client,
    required String baseUrl,
    required Ref ref,
  })  : _client = client,
        _baseUrl = baseUrl,
        _ref = ref;

  final http.Client _client;
  final String _baseUrl;
  final Ref _ref;

  Future<AdminProfile> getAdminProfile() async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/me');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AdminProfile.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw ApiException('Error al cargar perfil de administrador.',
        statusCode: response.statusCode);
  }

  Future<AdminDashboardData> getDashboardSummary() async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/dashboard/summary');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AdminDashboardData.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw ApiException('Error al cargar dashboard.',
        statusCode: response.statusCode);
  }

  Future<String> uploadFile(String filePath) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['url']?.toString() ?? '';
    }
    throw ApiException('Error al subir archivo.',
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
