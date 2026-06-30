import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/user_management_repository.dart';
import '../../data/models/user_management_models.dart';

final userListProvider =
    FutureProvider.family<List<dynamic>, UserListParams>((ref, params) async {
  final repository = ref.read(userManagementRepositoryProvider);
  return repository.listUsers(
    page: params.page,
    pageSize: params.pageSize,
    rol: params.rol,
    isVerified: params.isVerified,
    isActive: params.isActive,
    isSuspended: params.isSuspended,
    q: params.q,
  );
});

class UserListParams {
  final int page;
  final int pageSize;
  final String? rol;
  final bool? isVerified;
  final bool? isActive;
  final bool? isSuspended;
  final String? q;

  const UserListParams({
    this.page = 1,
    this.pageSize = 50,
    this.rol,
    this.isVerified,
    this.isActive,
    this.isSuspended,
    this.q,
  });

  UserListParams copyWith({
    int? page,
    int? pageSize,
    String? rol,
    bool? isVerified,
    bool? isActive,
    bool? isSuspended,
    String? q,
  }) {
    return UserListParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      rol: rol ?? this.rol,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isSuspended: isSuspended ?? this.isSuspended,
      q: q ?? this.q,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserListParams &&
          page == other.page &&
          pageSize == other.pageSize &&
          rol == other.rol &&
          isVerified == other.isVerified &&
          isActive == other.isActive &&
          isSuspended == other.isSuspended &&
          q == other.q;

  @override
  int get hashCode => Object.hash(
      page, pageSize, rol, isVerified, isActive, isSuspended, q);
}

final userManagementControllerProvider =
    Provider<UserManagementController>((ref) {
  return UserManagementController(ref);
});

class UserManagementController {
  UserManagementController(this._ref);

  final Ref _ref;

  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final repository = _ref.read(userManagementRepositoryProvider);
      return await repository.getUserDetails(userId);
    } on Exception {
      return null;
    }
  }

  Future<bool> updateUser(String userId, UserUpdateRequest request) async {
    try {
      final repository = _ref.read(userManagementRepositoryProvider);
      return await repository.updateUser(userId, request);
    } on Exception {
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      final repository = _ref.read(userManagementRepositoryProvider);
      return await repository.deleteUser(userId);
    } on Exception {
      return false;
    }
  }

  Future<bool> suspendUser(String userId, String reason) async {
    try {
      final repository = _ref.read(userManagementRepositoryProvider);
      return await repository.suspendUser(userId, reason);
    } on Exception {
      return false;
    }
  }

  Future<bool> unsuspendUser(String userId) async {
    try {
      final repository = _ref.read(userManagementRepositoryProvider);
      return await repository.unsuspendUser(userId);
    } on Exception {
      return false;
    }
  }

  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      final repository = _ref.read(userManagementRepositoryProvider);
      return await repository.changeUserRole(userId, newRole);
    } on Exception {
      return false;
    }
  }
}
