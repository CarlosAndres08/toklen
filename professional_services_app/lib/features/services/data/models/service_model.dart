import '../../../categories/data/models/category_model.dart';

/// Sub-modelo para las insignias (badges) del proveedor
class ServiceBadgeModel {
  const ServiceBadgeModel({
    this.id = '',
    this.name = '',
    this.iconUrl = '',
  });

  final String id;
  final String name;
  final String iconUrl;

  factory ServiceBadgeModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ServiceBadgeModel();
    return ServiceBadgeModel(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['nombre'])?.toString() ?? '',
      iconUrl: json['icon_url']?.toString() ?? '',
    );
  }
}

/// Sub-modelo para las imágenes de la galería del servicio
class ServiceImageModel {
  const ServiceImageModel({
    this.id = '',
    this.url = '',
    this.fechaCreacion,
  });

  final String id;
  final String url;
  final DateTime? fechaCreacion;

  DateTime? get createdAt => fechaCreacion;

  factory ServiceImageModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ServiceImageModel();
    return ServiceImageModel(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      fechaCreacion: (json['fecha_creacion'] ?? json['created_at']) != null
          ? DateTime.tryParse(json['fecha_creacion'] ?? json['created_at'])
          : null,
    );
  }
}

/// Sub-modelo resumido del proveedor que creó el servicio
class ServiceProviderModel {
  const ServiceProviderModel({
    this.id = '',
    this.nombre = '',
    this.email = '',
    this.profilePictureUrl = '',
    this.isVerified = false,
    this.isAvailable = true,
    this.latitude,
    this.longitude,
    this.badges = const [],
  });

  final String id;
  final String nombre;
  final String email;
  final String profilePictureUrl;
  final bool isVerified;
  final bool isAvailable;
  final double? latitude;
  final double? longitude;
  final List<ServiceBadgeModel> badges;

  String get name => nombre;

  factory ServiceProviderModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ServiceProviderModel();
    return ServiceProviderModel(
      id: json['id']?.toString() ?? '',
      nombre: (json['nombre'] ?? json['name'])?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profilePictureUrl: json['profile_picture_url']?.toString() ?? '',
      isVerified: json['is_verified'] == true,
      isAvailable: json['is_available'] != false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      badges: (json['badges'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ServiceBadgeModel.fromJson)
              .toList() ??
          const [],
    );
  }
}

/// Modelo Principal del Servicio
class ServiceModel {
  const ServiceModel({
    this.id = '',
    this.title = '',
    this.description = '',
    this.price = 0.0,
    this.isActive = true,
    this.isFeatured = false,
    this.latitude,
    this.longitude,
    this.distance,
    this.averageRating,
    this.reviewsCount = 0,
    this.fechaCreacion,
    this.provider,
    this.category,
    this.images = const [],
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final bool isActive;
  final bool isFeatured;
  final double? latitude;
  final double? longitude;
  final double? distance;
  final double? averageRating;
  final int reviewsCount;
  final DateTime? fechaCreacion;
  final ServiceProviderModel? provider;
  final CategoryModel? category;
  final List<ServiceImageModel> images;

  DateTime? get createdAt => fechaCreacion;

  factory ServiceModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ServiceModel();
    
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] == true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      fechaCreacion: (json['fecha_creacion'] ?? json['created_at']) != null
          ? DateTime.tryParse(json['fecha_creacion'] ?? json['created_at'])
          : null,
      
      provider: json['provider'] != null 
          ? ServiceProviderModel.fromJson(json['provider'] as Map<String, dynamic>) 
          : null,
      category: json['category'] != null 
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>) 
          : null,
          
      images: (json['images'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ServiceImageModel.fromJson)
              .toList() ??
          const [],
    );
  }
}

/// Modelo para crear un nuevo servicio (POST)
class ServiceCreateRequest {
  const ServiceCreateRequest({
    required this.title,
    required this.description,
    required this.price,
    required this.categoryId,
    this.isActive = true,
  });

  final String title;
  final String description;
  final double price;
  final String categoryId;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'category_id': categoryId,
      'is_active': isActive,
    };
  }
}

/// Modelo para editar un servicio existente (PUT)
class ServiceUpdateRequest {
  const ServiceUpdateRequest({
    this.title,
    this.description,
    this.price,
    this.isActive,
  });

  final String? title;
  final String? description;
  final double? price;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (price != null) data['price'] = price;
    if (isActive != null) data['is_active'] = isActive;
    return data;
  }
}
