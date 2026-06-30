import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/verification_repository.dart';
import '../../data/repositories/user_management_repository.dart';

final pendingVerificationsProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.read(verificationRepositoryProvider);
  return repository.getPendingVerifications();
});

final allProvidersProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.read(userManagementRepositoryProvider);
  return repository.listUsers(rol: 'provider', pageSize: 100);
});

final verificationControllerProvider =
    Provider<VerificationController>((ref) {
  return VerificationController(ref);
});

class VerificationController {
  VerificationController(this._ref);

  final Ref _ref;

  Future<bool> approveVerification(String userId) async {
    try {
      final repository = _ref.read(verificationRepositoryProvider);
      return await repository.approveVerification(userId);
    } on Exception {
      return false;
    }
  }

  Future<bool> rejectVerification(String userId, String reason) async {
    try {
      final repository = _ref.read(verificationRepositoryProvider);
      return await repository.rejectVerification(userId, reason);
    } on Exception {
      return false;
    }
  }
}
