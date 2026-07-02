import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

import '../../../../core/storage/token_storage.dart';

class AuthRepository {
  const AuthRepository({
    required Dio client,
    required TokenStorage tokenStorage,
  }) : _client = client,
       _tokenStorage = tokenStorage;

  final Dio _client;
  final TokenStorage _tokenStorage;

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    String rol = 'client',
  }) async {
    try {
      final response = await _client.post(
        '/api/v1/auth/register',
        data: {
          'nombre': name, // Usamos nombre para consistencia con backend
          'email': email,
          'password': password,
          'rol': rol,    // Usamos rol para consistencia con backend
        },
      );

      final UserModel user = UserModel.fromJson(response.data as Map<String, dynamic>);
      return AuthResponseModel(tokenType: 'bearer', user: user);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // Login usa Form-Data para OAuth2 en FastAPI.
      // Usamos un Map simple con content-type x-www-form-urlencoded para que Dio lo codifique correctamente.
      final response = await _client.post(
        '/api/v1/auth/login',
        data: {
          'username': email,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<UserModel> getCurrentUser(String accessToken) async {
    try {
      final response = await _client.get(
        '/api/v1/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  // Los métodos de persistencia se mantienen igual o se mueven a un Service
  // En el código original estaban en AuthRepository pero usaban TokenStorage directamente.
  // El AuthProvider actual usa TokenStorage por separado o inyectado.

  String _extractErrorMessage(Object? body) {
    if (body is Map<String, dynamic>) {
      final Object? detail = body['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }

      if (detail is List<dynamic> && detail.isNotEmpty) {
        final Object? firstError = detail.first;
        if (firstError is Map<String, dynamic>) {
          return firstError['msg']?.toString() ?? 'La solicitud no es válida.';
        }
      }
    }

    return 'No pudimos completar la solicitud. Inténtalo nuevamente.';
  }

  Future<void> persistToken(String accessToken) {
    return _tokenStorage.saveAccessToken(accessToken);
  }

  Future<String?> readToken() {
    return _tokenStorage.readAccessToken();
  }

  Future<void> clearSession() {
    return _tokenStorage.clear();
  }
}
