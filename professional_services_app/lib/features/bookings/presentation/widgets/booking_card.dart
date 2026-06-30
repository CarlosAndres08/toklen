import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/booking_model.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';
import '../../../reviews/data/models/review_model.dart';
import '../../../reviews/presentation/providers/review_provider.dart';
import '../../../reviews/presentation/widgets/review_form.dart';
import '../providers/booking_provider.dart';

/// Widget reutilizable para mostrar una tarjeta de reserva
class BookingCard extends ConsumerWidget {
  final BookingModel booking;
  final bool isProvider; // true si es vista de proveedor, false si es vista de cliente
  final VoidCallback? onStatusUpdate;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isProvider,
    this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final DateFormat timeFormat = DateFormat('HH:mm');
    final String contactId = isProvider ? booking.clientId : (booking.providerId ?? '');
    final String contactName = isProvider
        ? (booking.clientName ?? 'Cliente')
        : (booking.providerName ?? 'Proveedor');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre del servicio y estado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceTitle ?? 'Servicio',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isProvider ? Icons.person_outline : Icons.build_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isProvider
                                  ? (booking.clientName ?? 'Cliente')
                                  : 'Proveedor del servicio',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusBadge(),
              ],
            ),

            const Divider(height: 24),

            // Fecha y hora
            if (booking.startTime != null) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(booking.startTime!),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(booking.startTime!),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],

            // Notas de la reserva
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.note_outlined, size: 16, color: AppColors.textSecondary),
                        SizedBox(width: 6),
                        Text(
                          'Notas:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      booking.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Precio del servicio
            if (booking.servicePrice != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 20, color: AppColors.success),
                  const SizedBox(width: 6),
                  const Text(
                    'Precio del servicio:',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'S/ ${booking.servicePrice!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],

            // Botón "Chat" - contactar al proveedor (cliente) o al cliente (proveedor)
            if (contactId.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          contactId: contactId,
                          contactName: contactName,
                        ),
                      ),
                    );
                    if (context.mounted) ref.invalidate(inboxProvider);
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],

            // Botón "Dejar Reseña" para clientes cuando la reserva está completada
            if (!isProvider && booking.status == 'completed') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showReviewDialog(context, ref),
                  icon: const Icon(Icons.rate_review_outlined, size: 20),
                  label: const Text('Dejar Reseña'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],

            // Botones de acción para proveedores
            if (isProvider && booking.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(context, ref),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showConfirmDialog(context, ref),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Confirmar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Botón marcar como completada (solo para proveedores cuando está confirmed)
            if (isProvider && booking.status == 'confirmed') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCompleteDialog(context, ref),
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: const Text('Marcar como Completada'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showReviewDialog(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: ReviewForm(
          isLoading: ref.watch(createReviewControllerProvider).isLoading,
          onSubmit: (req) async {
            final request = ReviewCreateRequest(
              bookingId: booking.id,
              rating: req.rating,
              comment: req.comment,
            );
            return ref
                .read(createReviewControllerProvider.notifier)
                .executeCreate(request);
          },
        ),
      ),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reseña enviada exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (booking.status.toLowerCase()) {
      case 'confirmed':
        backgroundColor = AppColors.statusActiveBg;
        textColor = AppColors.statusActive;
        icon = Icons.check_circle;
        break;
      case 'completed':
        backgroundColor = AppColors.statusCompletedBg;
        textColor = AppColors.statusCompleted;
        icon = Icons.task_alt;
        break;
      case 'cancelled':
        backgroundColor = AppColors.statusCancelledBg;
        textColor = AppColors.statusCancelled;
        icon = Icons.cancel;
        break;
      case 'pending':
      default:
        backgroundColor = AppColors.statusPendingBg;
        textColor = AppColors.statusPending;
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            booking.getStatusText(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmDialog(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Reserva'),
        content: const Text('¿Estás seguro de confirmar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      const BookingStatusUpdate update = BookingStatusUpdate(
        status: 'confirmed',
      );
      await _updateStatus(context, ref, update);
    }
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Reserva'),
        content: const Text('¿Estás seguro de rechazar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      const BookingStatusUpdate update = BookingStatusUpdate(
        status: 'cancelled',
      );
      await _updateStatus(context, ref, update);
    }
  }

  Future<void> _showCompleteDialog(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar como Completada'),
        content: const Text('¿El servicio se completó exitosamente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Completar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      const BookingStatusUpdate update = BookingStatusUpdate(
        status: 'completed',
      );
      await _updateStatus(context, ref, update);
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    BookingStatusUpdate update,
  ) async {
    final bool success = await ref
        .read(updateBookingStatusControllerProvider.notifier)
        .updateStatus(
          bookingId: booking.id,
          statusUpdate: update,
        );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado actualizado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el estado'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}