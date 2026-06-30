import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart'; // Importamos el httpClientProvider
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';

// 1. Inyectamos el repositorio
final Provider<CategoryRepository> categoryRepositoryProvider = Provider<CategoryRepository>((Ref ref) {
  return CategoryRepository(
    client: ref.watch(httpClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
  );
});

// 2. Creamos el gestor de estado para la lista de categorías
final AsyncNotifierProvider<CategoryListNotifier, List<CategoryModel>> categoryListProvider =
    AsyncNotifierProvider<CategoryListNotifier, List<CategoryModel>>(CategoryListNotifier.new);

class CategoryListNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    // Al construirse, automáticamente llama al backend para traer la lista
    return _fetchCategories();
  }

  Future<List<CategoryModel>> _fetchCategories() async {
    final CategoryRepository repository = ref.read(categoryRepositoryProvider);
    return await repository.getCategories();
  }

  // Utilidad por si en el futuro queremos agregar un botón de "Actualizar" o "Pull to refresh"
  Future<void> refresh() async {
    state = const AsyncLoading<List<CategoryModel>>();
    state = await AsyncValue.guard(() => _fetchCategories());
  }
}