import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_exception.dart';
import '../models/booking_model.dart';

/// Repositorio de Reservas
/// Maneja todas las peticiones HTTP al backend para bookings
class BookingRepository {
  const BookingRepository({
    required http.Client client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// Crear nueva reserva - POST /api/v1/bookings/
  Future<BookingModel> createBooking({
    required String token,
    required BookingCreateRequest request,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/bookings/');

    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    final Map<String, dynamic> data = _decodeResponse(response);
    return BookingModel.fromJson(data);
  }

  /// Obtener mis reservas (como cliente) - GET /api/v1/bookings/my-bookings
  Future<List<BookingModel>> getMyBookings({
    required String token,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/bookings/my-bookings');

    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final dynamic data = _decodeResponseList(response);
    
    if (data is List) {
      return data
          .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return <BookingModel>[];
  }

  /// Obtener solicitudes de reserva (como proveedor) - GET /api/v1/bookings/requests
  Future<List<BookingModel>> getBookingRequests({
    required String token,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/bookings/requests');

    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final dynamic data = _decodeResponseList(response);
    
    if (data is List) {
      return data
          .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return <BookingModel>[];
  }

  /// Actualizar estado de reserva - PATCH /api/v1/bookings/{booking_id}/status
  Future<BookingModel> updateBookingStatus({
    required String token,
    required String bookingId,
    required BookingStatusUpdate statusUpdate,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/bookings/$bookingId/status');

    final http.Response response = await _client.patch(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(statusUpdate.toJson()),
    );

    final Map<String, dynamic> data = _decodeResponse(response);
    return BookingModel.fromJson(data);
  }

  /// Decodificar respuesta JSON para un solo objeto
  Map<String, dynamic> _decodeResponse(http.Response response) {
    final Object? decodedBody = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decodedBody is Map<String, dynamic>) {
        return decodedBody;
      }
      return <String, dynamic>{};
    }

    throw ApiException(
      _extractErrorMessage(decodedBody),
      statusCode: response.statusCode,
    );
  }

  /// Decodificar respuesta JSON para lista
  dynamic _decodeResponseList(http.Response response) {
    final Object? decodedBody = response.body.isEmpty
        ? <dynamic>[]
        : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    throw ApiException(
      _extractErrorMessage(decodedBody),
      statusCode: response.statusCode,
    );
  }

  /// Extraer mensaje de error del backend
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
