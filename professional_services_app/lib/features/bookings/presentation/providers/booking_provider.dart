import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';

/// Provider del repositorio de bookings
final Provider<BookingRepository> bookingRepositoryProvider =
    Provider<BookingRepository>((Ref ref) {
  return BookingRepository(
    client: ref.watch(dioProvider),
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
    final BookingRepository repository = ref.read(bookingRepositoryProvider);
    return repository.getMyBookings();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<BookingModel>>();
    state = await AsyncValue.guard(() => _fetchMyBookings());
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
    final BookingRepository repository = ref.read(bookingRepositoryProvider);
    return repository.getBookingRequests();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<BookingModel>>();
    state = await AsyncValue.guard(() => _fetchBookingRequests());
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
      final BookingRepository repository = ref.read(bookingRepositoryProvider);
      await repository.createBooking(request: request);
      state = const AsyncData<void>(null);
      ref.invalidate(myBookingsProvider);
      return true;
    } catch (e, st) {
      state = AsyncError<void>(e.toString(), st);
      return false;
    }
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
      final BookingRepository repository = ref.read(bookingRepositoryProvider);
      await repository.updateBookingStatus(
        bookingId: bookingId,
        statusUpdate: statusUpdate,
      );
      state = const AsyncData<void>(null);
      ref.invalidate(myBookingsProvider);
      ref.invalidate(bookingRequestsProvider);
      return true;
    } catch (e, st) {
      state = AsyncError<void>(e.toString(), st);
      return false;
    }
  }
}
