import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';

final verificationRepositoryProvider =
    Provider<VerificationRepository>((ref) {
  return VerificationRepository(
    client: ref.watch(dioProvider),
  );
});

class VerificationRepository {
  VerificationRepository({
    required Dio client,
  }) : _client = client;

  final Dio _client;

  Future<List<dynamic>> getPendingVerifications() async {
    try {
      final response = await _client.get('/api/v1/admin/providers/pending-verification');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException('Error al cargar verificaciones pendientes',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> approveVerification(String userId) async {
    try {
      await _client.post('/api/v1/admin/providers/$userId/approve-verification');
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al aprobar verificación',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> rejectVerification(String userId, String reason) async {
    try {
      await _client.post(
        '/api/v1/admin/providers/$userId/reject-verification',
        data: {'reason': reason},
      );
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al rechazar verificación',
          statusCode: e.response?.statusCode);
    }
  }
}
