import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(
    client: ref.watch(dioProvider),
  );
});

class AdminRepository {
  AdminRepository({
    required Dio client,
  }) : _client = client;

  final Dio _client;

  Future<AdminProfile> getAdminProfile() async {
    try {
      final response = await _client.get('/api/v1/admin/me');
      return AdminProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException('Error al cargar perfil de administrador.',
          statusCode: e.response?.statusCode);
    }
  }

  Future<AdminDashboardData> getDashboardSummary() async {
    try {
      final response = await _client.get('/api/v1/admin/dashboard/summary');
      return AdminDashboardData.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException('Error al cargar dashboard.',
          statusCode: e.response?.statusCode);
    }
  }

  Future<String> uploadFile(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _client.post(
        '/api/v1/admin/upload',
        data: formData,
      );
      return response.data['url']?.toString() ?? '';
    } on DioException catch (e) {
      throw ApiException('Error al subir archivo.',
          statusCode: e.response?.statusCode);
    }
  }
}
