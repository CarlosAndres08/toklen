import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';

final serviceManagementRepositoryProvider =
    Provider<ServiceManagementRepository>((ref) {
  return ServiceManagementRepository(
    client: ref.watch(dioProvider),
  );
});

class ServiceManagementRepository {
  ServiceManagementRepository({
    required Dio client,
  }) : _client = client;

  final Dio _client;

  Future<List<dynamic>> listServices() async {
    try {
      final response = await _client.get('/api/v1/admin/services');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException('Error al cargar servicios',
          statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> getServiceDetail(String serviceId) async {
    try {
      final response = await _client.get('/api/v1/admin/services/$serviceId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException('Error al cargar detalle del servicio',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> updateService(
      String serviceId, Map<String, dynamic> data) async {
    try {
      await _client.put(
        '/api/v1/admin/services/$serviceId',
        data: data,
      );
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al actualizar servicio',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> deleteService(String serviceId) async {
    try {
      await _client.delete('/api/v1/admin/services/$serviceId');
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al eliminar servicio',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> approveService(String serviceId) async {
    try {
      await _client.post('/api/v1/admin/services/$serviceId/approve');
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al aprobar servicio',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> rejectService(
      String serviceId, String reason) async {
    try {
      await _client.post(
        '/api/v1/admin/services/$serviceId/reject',
        data: {'reason': reason},
      );
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al rechazar servicio',
          statusCode: e.response?.statusCode);
    }
  }
}
