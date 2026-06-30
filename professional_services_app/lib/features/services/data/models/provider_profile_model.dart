import 'service_model.dart';

class ProviderProfileModel {
  const ProviderProfileModel({
    this.id = '',
    this.name = '',
    this.email = '',
    this.profilePictureUrl,
    this.isVerified = false,
    this.isAvailable = true,
    this.bio,
    this.latitude,
    this.longitude,
    this.serviceRadius,
    this.badges = const [],
    this.totalServices = 0,
    this.averageRating,
    this.totalReviews = 0,
    this.services = const [],
  });

  final String id;
  final String name;
  final String email;
  final String? profilePictureUrl;
  final bool isVerified;
  final bool isAvailable;
  final String? bio;
  final double? latitude;
  final double? longitude;
  final double? serviceRadius;
  final List<ServiceBadgeModel> badges;
  final int totalServices;
  final double? averageRating;
  final int totalReviews;
  final List<ServiceModel> services;

  factory ProviderProfileModel.fromJson(Map<String, dynamic> json) {
    return ProviderProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profilePictureUrl: json['profile_picture_url']?.toString(),
      isVerified: json['is_verified'] == true,
      isAvailable: json['is_available'] != false,
      bio: json['bio']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      serviceRadius: (json['service_radius'] as num?)?.toDouble(),
      badges: (json['badges'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ServiceBadgeModel.fromJson)
              .toList() ??
          const [],
      totalServices: (json['total_services'] as num?)?.toInt() ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      services: (json['services'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ServiceModel.fromJson)
              .toList() ??
          const [],
    );
  }
}
