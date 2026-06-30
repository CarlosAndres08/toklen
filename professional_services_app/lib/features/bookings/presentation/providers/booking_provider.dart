import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';

/// Provider del repositorio de bookings
final Provider<BookingRepository> bookingRepositoryProvider =
    Provider<BookingRepository>((Ref ref) {
  return BookingRepository(
    client: ref.watch(httpClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
  );
});

/// Provider para MIS RESERVAS (como cliente)
final AsyncNotifierProvider<MyBookingsNotifier, List<BookingModel>>
    myBookingsProvider =
    AsyncNotifierProvider<MyBookingsNotifier, List<BookingModel>>(
        MyBookingsNotifier.new);

class MyBookingsNotifier extends AsyncNotifier<List<BookingModel>> {
  @override
  Future<List<BookingModel>> build() async {
    return _fetchMyBookings();
  }

  Future<List<BookingModel>> _fetchMyBookings() async {
    final String token = _getAuthToken();
    final BookingRepository repository = ref.read(bookingRepositoryProvider);
    return repository.getMyBookings(token: token);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<BookingModel>>();
    state = await AsyncValue.guard(() => _fetchMyBookings());
  }

  String _getAuthToken() {
    final AuthState authState =
        ref.read(authControllerProvider).value ?? const AuthState();
    final String token = authState.accessToken ?? '';
    if (token.isEmpty) {
      throw const ApiException('No hay sesión activa.');
    }
    return token;
  }
}

/// Provider para SOLICITUDES DE RESERVA (como proveedor)
final AsyncNotifierProvider<BookingRequestsNotifier, List<BookingModel>>
    bookingRequestsProvider =
    AsyncNotifierProvider<BookingRequestsNotifier, List<BookingModel>>(
        BookingRequestsNotifier.new);

class BookingRequestsNotifier extends AsyncNotifier<List<BookingModel>> {
  @override
  Future<List<BookingModel>> build() async {
    return _fetchBookingRequests();
  }

  Future<List<BookingModel>> _fetchBookingRequests() async {
    final String token = _getAuthToken();
    final BookingRepository repository = ref.read(bookingRepositoryProvider);
    return repository.getBookingRequests(token: token);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<BookingModel>>();
    state = await AsyncValue.guard(() => _fetchBookingRequests());
  }

  String _getAuthToken() {
    final AuthState authState =
        ref.read(authControllerProvider).value ?? const AuthState();
    final String token = authState.accessToken ?? '';
    if (token.isEmpty) {
      throw const ApiException('No hay sesión activa.');
    }
    return token;
  }
}

/// Provider para CREAR RESERVA
final AsyncNotifierProvider<CreateBookingController, void>
    createBookingControllerProvider =
    AsyncNotifierProvider<CreateBookingController, void>(
        CreateBookingController.new);

class CreateBookingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> createBooking(BookingCreateRequest request) async {
    state = const AsyncLoading<void>();

    try {
      final String token = _getAuthToken();
      final BookingRepository repository = ref.read(bookingRepositoryProvider);

      await repository.createBooking(token: token, request: request);

      state = const AsyncData<void>(null);

      // Refrescar la lista de reservas
      ref.invalidate(myBookingsProvider);

      return true;
    } on ApiException catch (e, st) {
      state = AsyncError<void>(e.message, st);
      return false;
    } on Object catch (e, st) {
      state = AsyncError<void>('Error al crear la reserva.', st);
      return false;
    }
  }

  String _getAuthToken() {
    final AuthState authState =
        ref.read(authControllerProvider).value ?? const AuthState();
    final String token = authState.accessToken ?? '';
    if (token.isEmpty) {
      throw const ApiException('No hay sesión activa.');
    }
    return token;
  }
}

/// Provider para ACTUALIZAR ESTADO DE RESERVA
final AsyncNotifierProvider<UpdateBookingStatusController, void>
    updateBookingStatusControllerProvider =
    AsyncNotifierProvider<UpdateBookingStatusController, void>(
        UpdateBookingStatusController.new);

class UpdateBookingStatusController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> updateStatus({
    required String bookingId,
    required BookingStatusUpdate statusUpdate,
  }) async {
    state = const AsyncLoading<void>();

    try {
      final String token = _getAuthToken();
      final BookingRepository repository = ref.read(bookingRepositoryProvider);

      await repository.updateBookingStatus(
        token: token,
        bookingId: bookingId,
        statusUpdate: statusUpdate,
      );

      state = const AsyncData<void>(null);

      // Refrescar las listas
      ref.invalidate(myBookingsProvider);
      ref.invalidate(bookingRequestsProvider);

      return true;
    } on ApiException catch (e, st) {
      state = AsyncError<void>(e.message, st);
      return false;
    } on Object catch (e, st) {
      state = AsyncError<void>('Error al actualizar la reserva.', st);
      return false;
    }
  }

  String _getAuthToken() {
    final AuthState authState =
        ref.read(authControllerProvider).value ?? const AuthState();
    final String token = authState.accessToken ?? '';
    if (token.isEmpty) {
      throw const ApiException('No hay sesión activa.');
    }
    return token;
  }
}