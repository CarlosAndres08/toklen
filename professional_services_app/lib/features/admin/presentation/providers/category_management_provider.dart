import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/category_management_repository.dart';

final categoryListProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.read(categoryManagementRepositoryProvider);
  return repository.getAllCategories();
});

final categoryManagementControllerProvider =
    Provider<CategoryManagementController>((ref) {
  return CategoryManagementController(ref);
});

class CategoryManagementController {
  CategoryManagementController(this._ref);

  final Ref _ref;

  Future<bool> createCategory(Map<String, dynamic> data) async {
    try {
      final repository = _ref.read(categoryManagementRepositoryProvider);
      return await repository.createCategory(data);
    } on Exception {
      return false;
    }
  }

  Future<bool> updateCategory(
      String categoryId, Map<String, dynamic> data) async {
    try {
      final repository = _ref.read(categoryManagementRepositoryProvider);
      return await repository.updateCategory(categoryId, data);
    } on Exception {
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      final repository = _ref.read(categoryManagementRepositoryProvider);
      return await repository.deleteCategory(categoryId);
    } on Exception {
      return false;
    }
  }

  Future<bool> uploadCategoryImage(
      String categoryId, String imageUrl) async {
    try {
      final repository = _ref.read(categoryManagementRepositoryProvider);
      return await repository.uploadCategoryImage(categoryId, imageUrl);
    } on Exception {
      return false;
    }
  }

  Future<bool> reorderCategories(List<Map<String, dynamic>> order) async {
    try {
      final repository = _ref.read(categoryManagementRepositoryProvider);
      return await repository.reorderCategories(order);
    } on Exception {
      return false;
    }
  }
}
