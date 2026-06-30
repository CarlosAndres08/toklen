import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/provider_profile_model.dart';
import '../../data/models/service_model.dart';
import '../../data/repositories/service_repository.dart';

final Provider<ServiceRepository> serviceRepositoryProvider = Provider<ServiceRepository>((Ref ref) {
  return ServiceRepository(client: ref.watch(httpClientProvider), baseUrl: AppConfig.apiBaseUrl);
});

final AsyncNotifierProvider<ServiceListNotifier, List<ServiceModel>> serviceListProvider =
    AsyncNotifierProvider<ServiceListNotifier, List<ServiceModel>>(ServiceListNotifier.new);

final featuredServicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  return ref.read(serviceRepositoryProvider).getServices(featured: true);
});

final providerProfileProvider = FutureProvider.family<ProviderProfileModel, String>((ref, providerId) async {
  return ref.read(serviceRepositoryProvider).getProviderProfile(providerId: providerId);
});

class ServiceListNotifier extends AsyncNotifier<List<ServiceModel>> {
  String? _currentCategoryId;
  String? _currentSearchQuery;
  double? _currentLat;
  double? _currentLng;
  double? _currentRadius;
  String? _currentSortBy;

  @override
  Future<List<ServiceModel>> build() async => _fetch();
  Future<List<ServiceModel>> _fetch() async =>
      ref.read(serviceRepositoryProvider).getServices(
            categoryId: _currentCategoryId,
            searchQuery: _currentSearchQuery,
            lat: _currentLat,
            lng: _currentLng,
            radius: _currentRadius,
            sortBy: _currentSortBy,
          );

  void setLocation(double lat, double lng, {double radius = 10.0}) {
    _currentLat = lat;
    _currentLng = lng;
    _currentRadius = radius;
  }

  Future<void> filterByCategory(String? categoryId) async {
    _currentCategoryId = categoryId;
    _currentSearchQuery = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }
  Future<void> search(String? query) async {
    _currentSearchQuery = query;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }
  Future<void> sortBy(String? sortBy) async {
    _currentSortBy = sortBy;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }
  Future<void> refreshAll() async {
    _currentCategoryId = null;
    _currentSearchQuery = null;
    _currentSortBy = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }
}

final AsyncNotifierProvider<CreateServiceController, void> createServiceControllerProvider = AsyncNotifierProvider(CreateServiceController.new);
class CreateServiceController extends AsyncNotifier<void> {
  @override Future<void> build() async {}
  Future<bool> executeCreate(ServiceCreateRequest request) async {
    state = const AsyncLoading();
    try {
      final token = ref.read(authControllerProvider).value?.accessToken ?? '';
      await ref.read(serviceRepositoryProvider).createService(token: token, request: request);
      state = const AsyncData(null);
      ref.invalidate(serviceListProvider);
      return true;
    } catch (e, st) { state = AsyncError('Error al publicar.', st); return false; }
  }
}

final AsyncNotifierProvider<UpdateServiceController, void> updateServiceControllerProvider = AsyncNotifierProvider(UpdateServiceController.new);
class UpdateServiceController extends AsyncNotifier<void> {
  @override Future<void> build() async {}
  Future<bool> executeUpdate({required String serviceId, required ServiceUpdateRequest request}) async {
    state = const AsyncLoading();
    try {
      final token = ref.read(authControllerProvider).value?.accessToken ?? '';
      await ref.read(serviceRepositoryProvider).updateService(token: token, serviceId: serviceId, request: request);
      state = const AsyncData(null);
      ref.invalidate(serviceListProvider);
      return true;
    } catch (e, st) { state = AsyncError('Error al actualizar.', st); return false; }
  }
}

final AsyncNotifierProvider<UploadServiceImageController, void> uploadServiceImageControllerProvider = AsyncNotifierProvider(UploadServiceImageController.new);
class UploadServiceImageController extends AsyncNotifier<void> {
  @override Future<void> build() async {}
  Future<bool> executeUpload({required String serviceId, required List<int> imageBytes, required String fileName}) async {
    state = const AsyncLoading();
    try {
      final token = ref.read(authControllerProvider).value?.accessToken ?? '';
      await ref.read(serviceRepositoryProvider).uploadServiceImage(token: token, serviceId: serviceId, imageBytes: imageBytes, fileName: fileName);
      state = const AsyncData(null);
      ref.invalidate(serviceListProvider);
      return true;
    } catch (e, st) { state = AsyncError('Error al subir.', st); return false; }
  }
}

final AsyncNotifierProvider<AvailabilityToggleController, void> availabilityToggleControllerProvider =
    AsyncNotifierProvider<AvailabilityToggleController, void>(AvailabilityToggleController.new);
class AvailabilityToggleController extends AsyncNotifier<void> {
  @override Future<void> build() async {}
  Future<bool> toggle() async {
    state = const AsyncLoading();
    try {
      final token = ref.read(authControllerProvider).value?.accessToken ?? '';
      await ref.read(serviceRepositoryProvider).toggleAvailability(token: token);
      state = const AsyncData(null);
      ref.invalidate(authControllerProvider);
      return true;
    } catch (e, st) { state = AsyncError('Error al cambiar disponibilidad.', st); return false; }
  }
}

final AsyncNotifierProvider<DeleteServiceImageController, void> deleteServiceImageControllerProvider = AsyncNotifierProvider(DeleteServiceImageController.new);
class DeleteServiceImageController extends AsyncNotifier<void> {
  @override Future<void> build() async {}
  Future<bool> executeDelete({required String serviceId, required String imageId}) async {
    state = const AsyncLoading();
    try {
      final token = ref.read(authControllerProvider).value?.accessToken ?? '';
      await ref.read(serviceRepositoryProvider).deleteServiceImage(token: token, serviceId: serviceId, imageId: imageId);
      state = const AsyncData(null);
      ref.invalidate(serviceListProvider);
      return true;
    } catch (e, st) { state = AsyncError('Error al borrar la foto.', st); return false; }
  }
}