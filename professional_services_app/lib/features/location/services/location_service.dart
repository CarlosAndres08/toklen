import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../services/presentation/providers/service_provider.dart';

class LocationService {
  const LocationService({required http.Client client, required String baseUrl})
      : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

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
    required String token,
    required double latitude,
    required double longitude,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/users/me');
    final http.Response response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    if (response.statusCode >= 300) {
      throw ApiException('Error al actualizar ubicación.', statusCode: response.statusCode);
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(
    client: ref.watch(httpClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
  );
});

final locationControllerProvider = FutureProvider<void>((ref) async {
  final authState = ref.read(authControllerProvider).value;
  if (authState == null || authState.accessToken == null) return;

  final service = ref.read(locationServiceProvider);
  final position = await service.getCurrentPosition();
  if (position == null) return;

  await service.updateUserLocation(
    token: authState.accessToken!,
    latitude: position.latitude,
    longitude: position.longitude,
  );

  ref.read(serviceListProvider.notifier).setLocation(
    position.latitude,
    position.longitude,
  );
});
