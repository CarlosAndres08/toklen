import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/schedule_model.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(
    client: ref.watch(httpClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
  );
});

class ScheduleRepository {
  ScheduleRepository({
    required http.Client client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<List<ScheduleModel>> getProviderSchedule(String providerId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/schedules/$providerId');
    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body;
      if (body.isEmpty) return [];
      final decoded = jsonDecode(body) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ScheduleModel.fromJson)
          .toList();
    }
    throw ApiException('Error al cargar horarios.',
        statusCode: response.statusCode);
  }

  Future<bool> deleteSchedule(String token, String scheduleId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/schedules/$scheduleId');
    final response = await _client.delete(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 204) return true;
    throw ApiException('Error al eliminar horario.',
        statusCode: response.statusCode);
  }

  Future<ScheduleModel> createSchedule(
      String token, ScheduleCreateRequest req) async {
    final uri = Uri.parse('$_baseUrl/api/v1/schedules/');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(req.toJson()),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ScheduleModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    throw ApiException(
        data is Map ? data['detail']?.toString() ?? 'Error.' : 'Error.',
        statusCode: response.statusCode);
  }
}
