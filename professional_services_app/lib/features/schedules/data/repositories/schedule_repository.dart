import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/schedule_model.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(
    client: ref.watch(dioProvider),
  );
});

class ScheduleRepository {
  ScheduleRepository({
    required Dio client,
  }) : _client = client;

  final Dio _client;

  Future<List<ScheduleModel>> getProviderSchedule(String providerId) async {
    try {
      final response = await _client.get('/api/v1/schedules/$providerId');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map(ScheduleModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException('Error al cargar horarios.',
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _client.delete('/api/v1/schedules/$scheduleId');
      return true;
    } on DioException catch (e) {
      throw ApiException('Error al eliminar horario.',
          statusCode: e.response?.statusCode);
    }
  }

  Future<ScheduleModel> createSchedule(ScheduleCreateRequest req) async {
    try {
      final response = await _client.post(
        '/api/v1/schedules/',
        data: req.toJson(),
      );
      return ScheduleModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ApiException(
          data is Map ? data['detail']?.toString() ?? 'Error.' : 'Error.',
          statusCode: e.response?.statusCode);
    }
  }
}
