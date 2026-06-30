class DashboardSummary {
  final double totalRevenue;
  final double conversionRate;
  final int newUsers7d;
  final int totalUsers;
  final int totalProviders;
  final int totalServices;
  final int totalBookings;
  final int verifiedProviders;
  final int suspendedUsers;

  const DashboardSummary({
    this.totalRevenue = 0,
    this.conversionRate = 0,
    this.newUsers7d = 0,
    this.totalUsers = 0,
    this.totalProviders = 0,
    this.totalServices = 0,
    this.totalBookings = 0,
    this.verifiedProviders = 0,
    this.suspendedUsers = 0,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DashboardSummary();
    return DashboardSummary(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 0,
      newUsers7d: json['new_users_7d'] as int? ?? 0,
      totalUsers: json['total_users'] as int? ?? 0,
      totalProviders: json['total_providers'] as int? ?? 0,
      totalServices: json['total_services'] as int? ?? 0,
      totalBookings: json['total_bookings'] as int? ?? 0,
      verifiedProviders: json['verified_providers'] as int? ?? 0,
      suspendedUsers: json['suspended_users'] as int? ?? 0,
    );
  }
}

class TopServiceModel {
  final String serviceId;
  final String title;
  final double averageRating;
  final int totalReviews;
  final String providerName;

  const TopServiceModel({
    this.serviceId = '',
    this.title = '',
    this.averageRating = 0,
    this.totalReviews = 0,
    this.providerName = '',
  });

  factory TopServiceModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TopServiceModel();
    return TopServiceModel(
      serviceId: json['service_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      providerName: json['provider_name']?.toString() ?? '',
    );
  }
}

class AdminDashboardData {
  final DashboardSummary summary;
  final List<TopServiceModel> topServices;

  const AdminDashboardData({
    required this.summary,
    required this.topServices,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      summary: DashboardSummary.fromJson(
          json['summary'] as Map<String, dynamic>?),
      topServices: (json['top_services'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(TopServiceModel.fromJson)
              .toList() ??
          [],
    );
  }
}

class AdminProfile {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? apellido;

  const AdminProfile({
    this.id = 0,
    this.name = '',
    this.email = '',
    this.role = '',
    this.phone,
    this.apellido,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      phone: json['phone']?.toString(),
      apellido: json['apellido']?.toString(),
    );
  }
}
