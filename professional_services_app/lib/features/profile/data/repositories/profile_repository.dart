import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // <-- Import necesario para el formato de imagen

import '../../../../core/network/api_exception.dart';
import '../../../auth/data/models/user_model.dart';

class ProfileRepository {
  const ProfileRepository({
    required http.Client client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// Actualiza los datos de texto del perfil.
  Future<UserModel> updateProfile({
    required String token,
    String? name,
    String? phone,
    String? bio,
    String? address,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/users/me');
    
    // Solo enviamos los campos que no sean nulos
    final Map<String, dynamic> body = <String, dynamic>{};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (bio != null) body['bio'] = bio;
    if (address != null) body['address'] = address;

    final http.Response response = await _client.put(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final Map<String, dynamic> data = _decodeResponse(response);
    return UserModel.fromJson(data);
  }

  /// Sube la foto de perfil (Blindado para Flutter Web especificando MediaType)
  Future<UserModel> uploadProfilePicture({
    required String token,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/users/me/profile-picture');
    
    // 🔥 PASO DE INGENIERÍA: Detectar el tipo de archivo por su extensión
    final String extension = fileName.split('.').last.toLowerCase();
    MediaType contentType;
    
    switch (extension) {
      case 'png':
        contentType = MediaType('image', 'png');
        break;
      case 'jpg':
      case 'jpeg':
        contentType = MediaType('image', 'jpeg');
        break;
      case 'webp':
        contentType = MediaType('image', 'webp');
        break;
      case 'gif':
        contentType = MediaType('image', 'gif');
        break;
      default:
        // Si no sabemos, mandamos un tipo genérico
        contentType = MediaType('application', 'octet-stream');
    }

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file', // Mismo nombre que pide FastAPI
          fileBytes,
          filename: fileName,
          contentType: contentType, // <-- AHORA SÍ ENVIAMOS EL FORMATO CORRECTO
        ),
      );

    final http.StreamedResponse streamedResponse = await _client.send(request);
    final http.Response response = await http.Response.fromStream(streamedResponse);

    final Map<String, dynamic> data = _decodeResponse(response);
    return UserModel.fromJson(data);
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
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List<dynamic> && detail.isNotEmpty) {
        final Object? firstError = detail.first;
        if (firstError is Map<String, dynamic>) {
          return firstError['msg']?.toString() ?? 'Dato invalido.';
        }
      }
    }
    return 'Error al actualizar el perfil.';
  }
}