import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_card.dart';

/// Pantalla de Solicitudes de Reservas (Vista del Proveedor)
class BookingRequestsScreen extends ConsumerStatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  ConsumerState<BookingRequestsScreen> createState() =>
      _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends ConsumerState<BookingRequestsScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar solicitudes al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingRequestsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<BookingModel>> requestsState =
        ref.watch(bookingRequestsProvider);
    
    final String userRole =
        ref.watch(authControllerProvider).value?.user?.role ?? 'client';

    // Si no es proveedor, mostrar mensaje
    if (userRole != 'provider') {
      return _buildNotProviderState();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Solicitudes de Reserva',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {
              ref.read(bookingRequestsProvider.notifier).refresh();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: requestsState.when(
        data: (requests) => _buildRequestsList(requests),
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildRequestsList(List<BookingModel> requests) {
    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    // Separar por estado
    final List<BookingModel> pendingRequests =
        requests.where((b) => b.status == 'pending').toList();
    final List<BookingModel> confirmedRequests =
        requests.where((b) => b.status == 'confirmed').toList();
    final List<BookingModel> otherRequests = requests
        .where((b) => b.status != 'pending' && b.status != 'confirmed')
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(bookingRequestsProvider.notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección de pendientes
          if (pendingRequests.isNotEmpty) ...[
            _buildSectionHeader(
              'Pendientes',
              pendingRequests.length,
              AppColors.warning,
              Icons.schedule,
            ),
            const SizedBox(height: 12),
            ...pendingRequests.map((booking) => BookingCard(
                  booking: booking,
                  isProvider: true,
                  onStatusUpdate: () {
                    ref.read(bookingRequestsProvider.notifier).refresh();
                  },
                )),
          ],

          // Sección de confirmadas
          if (confirmedRequests.isNotEmpty) ...[
            if (pendingRequests.isNotEmpty) const SizedBox(height: 24),
            _buildSectionHeader(
              'Confirmadas',
              confirmedRequests.length,
              AppColors.success,
              Icons.check_circle,
            ),
            const SizedBox(height: 12),
            ...confirmedRequests.map((booking) => BookingCard(
                  booking: booking,
                  isProvider: true,
                  onStatusUpdate: () {
                    ref.read(bookingRequestsProvider.notifier).refresh();
                  },
                )),
          ],

          // Sección de otras (completadas/canceladas)
          if (otherRequests.isNotEmpty) ...[
            if (pendingRequests.isNotEmpty || confirmedRequests.isNotEmpty)
              const SizedBox(height: 24),
            _buildSectionHeader(
              'Historial',
              otherRequests.length,
              AppColors.textSecondary,
              Icons.history,
            ),
            const SizedBox(height: 12),
            ...otherRequests.map((booking) => BookingCard(
                  booking: booking,
                  isProvider: true,
                  onStatusUpdate: null,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Cargando solicitudes...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar solicitudes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(bookingRequestsProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay solicitudes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cuando los clientes reserven tus servicios,\naparecerán aquí',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotProviderState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.work_off_outlined,
              size: 100,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Solo para Proveedores',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Esta sección está disponible solo para usuarios con rol de proveedor',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
