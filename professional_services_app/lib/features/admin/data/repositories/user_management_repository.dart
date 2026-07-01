import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/user_management_models.dart';

final userManagementRepositoryProvider =
    Provider<UserManagementRepository>((ref) {
  return UserManagementRepository(
    client: ref.watch(dioProvider),
  );
});

class UserManagementRepository {
  UserManagementRepository({
    required Dio client,
  }) : _client = client;

  final Dio _client;

  Future<List<dynamic>> listUsers({
    int page = 1,
    int pageSize = 20,
    String? rol,
    bool? isVerified,
    bool? isActive,
    bool? isSuspended,
    String? q,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (rol != null) params['rol'] = rol;
      if (isVerified != null) params['is_verified'] = isVerified;
      if (isActive != null) params['is_active'] = isActive;
      if (isSuspended != null) params['is_suspended'] = isSuspended;
      if (q != null && q.isNotEmpty) params['q'] = q;

      final response = await _client.get(
        '/api/v1/admin/users',
        queryParameters: params,
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException('Error al cargar usuarios',
          statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final response = await _client.get('/api/v1/admin/users/$userId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException('Error al cargar detalles de usuario',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> updateUser(String userId, UserUpdateRequest request) async {
    try {
      await _client.put(
        '/api/v1/admin/users/$userId',
        data: request.toJson(),
      );
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al actualizar usuario',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _client.delete('/api/v1/admin/users/$userId');
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al eliminar usuario',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> suspendUser(String userId, String reason) async {
    try {
      await _client.post(
        '/api/v1/admin/users/$userId/suspend',
        data: {'reason': reason},
      );
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al suspender usuario',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> unsuspendUser(String userId) async {
    try {
      await _client.post('/api/v1/admin/users/$userId/unsuspend');
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al reactivar usuario',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      await _client.post(
        '/api/v1/admin/users/$userId/change-role',
        data: {'rol': newRole},
      );
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al cambiar rol de usuario',
          statusCode: e.response?.statusCode);
    }
  }
}
