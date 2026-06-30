import 'user_model.dart';

class AuthResponseModel {
  const AuthResponseModel({this.accessToken, this.tokenType, this.user});

  final String? accessToken;
  final String? tokenType;
  final UserModel? user;

  factory AuthResponseModel.fromJson(Map<String, dynamic>? json) {
    final Map<String, dynamic> data = json ?? <String, dynamic>{};
    final Object? userValue = data['user'];

    return AuthResponseModel(
      accessToken: data['access_token']?.toString() ?? '',
      tokenType: data['token_type']?.toString() ?? 'bearer',
      user: userValue is Map<String, dynamic>
          ? UserModel.fromJson(userValue)
          : const UserModel(),
    );
  }
}
