import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../models/booking_model.dart';

class BookingRepository {
  const BookingRepository({
    required Dio client,
  }) : _client = client;

  final Dio _client;

  Future<BookingModel> createBooking({
    required BookingCreateRequest request,
  }) async {
    try {
      final response = await _client.post(
        '/api/v1/bookings/',
        data: request.toJson(),
      );
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<BookingModel>> getMyBookings() async {
    try {
      final response = await _client.get('/api/v1/bookings/my-bookings');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => BookingModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException('Error al cargar mis reservas.', statusCode: e.response?.statusCode);
    }
  }

  Future<List<BookingModel>> getBookingRequests() async {
    try {
      final response = await _client.get('/api/v1/bookings/requests');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => BookingModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException('Error al cargar solicitudes de reserva.', statusCode: e.response?.statusCode);
    }
  }

  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required BookingStatusUpdate statusUpdate,
  }) async {
    try {
      final response = await _client.patch(
        '/api/v1/bookings/$bookingId/status',
        data: statusUpdate.toJson(),
      );
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _extractErrorMessage(Object? body) {
    if (body is Map<String, dynamic>) {
      final Object? detail = body['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (detail is List<dynamic> && detail.isNotEmpty) {
        final Object? firstError = detail.first;
        if (firstError is Map<String, dynamic>) {
          return firstError['msg']?.toString() ?? 'Error en los datos enviados.';
        }
      }
    }
    return 'Error al procesar la reserva.';
  }
}
