import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../services/presentation/providers/service_provider.dart';

class LocationService {
  const LocationService({required Dio client})
      : _client = client;

  final Dio _client;

  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<void> updateUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _client.put(
        '/api/v1/users/me',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
    } on DioException catch (e) {
      throw ApiException('Error al actualizar ubicación.', statusCode: e.response?.statusCode);
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(
    client: ref.watch(dioProvider),
  );
});

final locationControllerProvider = FutureProvider<void>((ref) async {
  final authState = ref.read(authControllerProvider).value;
  if (authState == null || authState.accessToken == null) return;

  final service = ref.read(locationServiceProvider);
  final position = await service.getCurrentPosition();
  if (position == null) return;

  await service.updateUserLocation(
    latitude: position.latitude,
    longitude: position.longitude,
  );

  ref.read(serviceListProvider.notifier).setLocation(
    position.latitude,
    position.longitude,
  );
});
