import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/service_management_repository.dart';

final serviceListProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.read(serviceManagementRepositoryProvider);
  return repository.listServices();
});

final serviceManagementControllerProvider =
    Provider<ServiceManagementController>((ref) {
  return ServiceManagementController(ref);
});

class ServiceManagementController {
  ServiceManagementController(this._ref);

  final Ref _ref;

  Future<Map<String, dynamic>?> getServiceDetail(String serviceId) async {
    try {
      final repository = _ref.read(serviceManagementRepositoryProvider);
      return await repository.getServiceDetail(serviceId);
    } on Exception {
      return null;
    }
  }

  Future<bool> updateService(
      String serviceId, Map<String, dynamic> data) async {
    try {
      final repository = _ref.read(serviceManagementRepositoryProvider);
      return await repository.updateService(serviceId, data);
    } on Exception {
      return false;
    }
  }

  Future<bool> deleteService(String serviceId) async {
    try {
      final repository = _ref.read(serviceManagementRepositoryProvider);
      return await repository.deleteService(serviceId);
    } on Exception {
      return false;
    }
  }

  Future<bool> approveService(String serviceId) async {
    try {
      final repository = _ref.read(serviceManagementRepositoryProvider);
      return await repository.approveService(serviceId);
    } on Exception {
      return false;
    }
  }

  Future<bool> rejectService(String serviceId, String reason) async {
    try {
      final repository = _ref.read(serviceManagementRepositoryProvider);
      return await repository.rejectService(serviceId, reason);
    } on Exception {
      return false;
    }
  }
}
