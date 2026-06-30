import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/user_management_models.dart';

final userManagementRepositoryProvider =
    Provider<UserManagementRepository>((ref) {
  return UserManagementRepository(
    client: ref.watch(httpClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
    ref: ref,
  );
});

class UserManagementRepository {
  UserManagementRepository({
    required http.Client client,
    required String baseUrl,
    required Ref ref,
  })  : _client = client,
        _baseUrl = baseUrl,
        _ref = ref;

  final http.Client _client;
  final String _baseUrl;
  final Ref _ref;

  Future<List<dynamic>> listUsers({
    int page = 1,
    int pageSize = 20,
    String? rol,
    bool? isVerified,
    bool? isActive,
    bool? isSuspended,
    String? q,
  }) async {
    final token = await _getToken();
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (rol != null) params['rol'] = rol;
    if (isVerified != null) params['is_verified'] = isVerified.toString();
    if (isActive != null) params['is_active'] = isActive.toString();
    if (isSuspended != null) params['is_suspended'] = isSuspended.toString();
    if (q != null && q.isNotEmpty) params['q'] = q;
    final uri = Uri.parse('$_baseUrl/api/v1/admin/users')
        .replace(queryParameters: params);
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw ApiException('Error al cargar usuarios',
        statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/users/$userId');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Error al cargar detalles de usuario',
        statusCode: response.statusCode);
  }

  Future<bool> updateUser(String userId, UserUpdateRequest request) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/users/$userId');
    final response = await _client.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw ApiException('Error al actualizar usuario',
        statusCode: response.statusCode);
  }

  Future<bool> deleteUser(String userId) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/users/$userId');
    final response = await _client.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw ApiException('Error al eliminar usuario',
        statusCode: response.statusCode);
  }

  Future<bool> suspendUser(String userId, String reason) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/users/$userId/suspend');
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
    throw ApiException('Error al suspender usuario',
        statusCode: response.statusCode);
  }

  Future<bool> unsuspendUser(String userId) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/users/$userId/unsuspend');
    final response = await _client.post(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw ApiException('Error al reactivar usuario',
        statusCode: response.statusCode);
  }

  Future<bool> changeUserRole(String userId, String newRole) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/admin/users/$userId/change-role');
    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'rol': newRole}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw ApiException('Error al cambiar rol de usuario',
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
