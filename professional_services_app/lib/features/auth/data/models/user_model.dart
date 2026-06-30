import 'badge_model.dart';

class UserModel {
  const UserModel({
    this.id,
    this.name,
    this.email,
    this.role,
    this.createdAt,
    this.phone,
    this.bio,
    this.address,
    this.latitude,
    this.longitude,
    this.serviceRadius,
    this.profilePictureUrl,
    this.isVerified,
    this.isAvailable,
    this.idDocumentUrl,
    this.badges = const <BadgeModel>[],
  });

  final String? id;
  final String? name;
  final String? email;
  final String? role;
  final DateTime? createdAt;
  final String? phone;
  final String? bio;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? serviceRadius;
  final String? profilePictureUrl;
  final bool? isVerified;
  final bool? isAvailable;
  final String? idDocumentUrl;
  final List<BadgeModel> badges;

  factory UserModel.fromJson(Map<String, dynamic>? json) {
    final Map<String, dynamic> data = json ?? <String, dynamic>{};
    final Object? badgesValue = data['badges'];

    return UserModel(
      id: data['id']?.toString() ?? '',
      name: (data['name'] ?? data['nombre'])?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      role: (data['role'] ?? data['rol'])?.toString() ?? 'client',
      createdAt: _parseDate(data['created_at'] ?? data['fecha_creacion']),
      phone: data['phone']?.toString() ?? '',
      bio: data['bio']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      serviceRadius: (data['service_radius'] as num?)?.toDouble(),
      profilePictureUrl: data['profile_picture_url']?.toString() ?? '',
      isVerified: data['is_verified'] == true,
      isAvailable: data['is_available'] != false,
      idDocumentUrl: data['id_document_url']?.toString() ?? '',
      badges: badgesValue is List<dynamic>
          ? badgesValue
                .whereType<Map<String, dynamic>>()
                .map(BadgeModel.fromJson)
                .toList(growable: false)
          : const <BadgeModel>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (bio != null) 'bio': bio,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (serviceRadius != null) 'service_radius': serviceRadius,
      if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
      if (isAvailable != null) 'is_available': isAvailable,
    };
  }

  static DateTime? _parseDate(Object? value) {
    final String rawValue = value?.toString() ?? '';
    if (rawValue.isEmpty) {
      return null;
    }

    return DateTime.tryParse(rawValue);
  }
}
