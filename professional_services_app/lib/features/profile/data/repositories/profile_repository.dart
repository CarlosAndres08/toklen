import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/data/models/user_model.dart';

class ProfileRepository {
  const ProfileRepository({
    required Dio client,
  }) : _client = client;

  final Dio _client;

  /// Actualiza los datos de texto del perfil.
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? bio,
    String? address,
  }) async {
    try {
      // Solo enviamos los campos que no sean nulos
      final Map<String, dynamic> body = {};
      if (name != null && name.isNotEmpty) body['nombre'] = name; // Usamos nombre para consistencia
      if (phone != null) body['phone'] = phone;
      if (bio != null) body['bio'] = bio;
      if (address != null) body['address'] = address;

      final response = await _client.put(
        '/api/v1/users/me',
        data: body,
      );

      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Sube la foto de perfil
  Future<UserModel> uploadProfilePicture({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final response = await _client.post(
        '/api/v1/users/me/profile-picture',
        data: formData,
      );

      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _extractErrorMessage(Object? body) {
    if (body is Map<String, dynamic>) {
      final Object? detail = body['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List<dynamic> && detail.isNotEmpty) {
        final Object? firstError = detail.first;
        if (firstError is Map<String, dynamic>) {
          return firstError['msg']?.toString() ?? 'Dato inválido.';
        }
      }
    }
    return 'Error al actualizar el perfil.';
  }
}
