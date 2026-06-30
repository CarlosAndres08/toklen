class FavoriteModel {
  final String id;
  final String serviceId;
  final String? createdAt;

  const FavoriteModel({
    this.id = '',
    this.serviceId = '',
    this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FavoriteModel();
    return FavoriteModel(
      id: json['id']?.toString() ?? '',
      serviceId: json['service_id']?.toString() ?? '',
      createdAt: json['fecha_creacion']?.toString(),
    );
  }
}
