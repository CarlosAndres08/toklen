import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final verificationRepositoryProvider =
    Provider<VerificationRepository>((ref) {
  return VerificationRepository(
    client: ref.watch(httpClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
    ref: ref,
  );
});

class VerificationRepository {
  VerificationRepository({
    required http.Client client,
    required String baseUrl,
    required Ref ref,
  })  : _client = client,
        _baseUrl = baseUrl,
        _ref = ref;

  final http.Client _client;
  final String _baseUrl;
  final Ref _ref;

  Future<List<dynamic>> getPendingVerifications() async {
    final token = await _getToken();
    final uri =
        Uri.parse('$_baseUrl/api/v1/admin/providers/pending-verification');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw ApiException('Error al cargar verificaciones pendientes',
        statusCode: response.statusCode);
  }

  Future<bool> approveVerification(String userId) async {
    final token = await _getToken();
    final uri = Uri.parse(
        '$_baseUrl/api/v1/admin/providers/$userId/approve-verification');
    final response = await _client.post(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw ApiException('Error al aprobar verificación',
        statusCode: response.statusCode);
  }

  Future<bool> rejectVerification(String userId, String reason) async {
    final token = await _getToken();
    final uri = Uri.parse(
        '$_baseUrl/api/v1/admin/providers/$userId/reject-verification');
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
    throw ApiException('Error al rechazar verificación',
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
