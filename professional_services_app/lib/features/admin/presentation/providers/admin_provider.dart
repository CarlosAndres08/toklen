import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_models.dart';
import '../../data/repositories/admin_repository.dart';

final adminProfileProvider = FutureProvider<AdminProfile>((ref) async {
  final repository = ref.read(adminRepositoryProvider);
  return repository.getAdminProfile();
});

final adminDashboardProvider =
    FutureProvider<AdminDashboardData>((ref) async {
  final repository = ref.read(adminRepositoryProvider);
  return repository.getDashboardSummary();
});


