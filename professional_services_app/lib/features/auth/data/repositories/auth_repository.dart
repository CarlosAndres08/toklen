import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRepository {
  const AuthRepository({
    required http.Client client,
    required String baseUrl,
    required TokenStorage tokenStorage,
  }) : _client = client,
       _baseUrl = baseUrl,
       _tokenStorage = tokenStorage;

  final http.Client _client;
  final String _baseUrl;
  final TokenStorage _tokenStorage;

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    String role = 'client',
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/auth/register');
    final http.Response response = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    final Map<String, dynamic> data = _decodeResponse(response);
    final UserModel user = UserModel.fromJson(data);

    return AuthResponseModel(tokenType: 'bearer', user: user);
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/auth/login');
    final http.Response response = await _client.post(
      uri,
      headers: const <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: <String, String>{'username': email, 'password': password},
    );

    final Map<String, dynamic> data = _decodeResponse(response);
    return AuthResponseModel.fromJson(data);
  }

  Future<UserModel> getCurrentUser(String accessToken) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/auth/me');
    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    return UserModel.fromJson(_decodeResponse(response));
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

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final Object? decodedBody = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decodedBody is Map<String, dynamic>) {
        return decodedBody;
      }

      return <String, dynamic>{};
    }

    throw ApiException(
      _extractErrorMessage(decodedBody),
      statusCode: response.statusCode,
    );
  }

  String _extractErrorMessage(Object? body) {
    if (body is Map<String, dynamic>) {
      final Object? detail = body['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }

      if (detail is List<dynamic> && detail.isNotEmpty) {
        final Object? firstError = detail.first;
        if (firstError is Map<String, dynamic>) {
          return firstError['msg']?.toString() ?? 'La solicitud no es valida.';
        }
      }
    }

    return 'No pudimos completar la solicitud. Intentalo nuevamente.';
  }
}
