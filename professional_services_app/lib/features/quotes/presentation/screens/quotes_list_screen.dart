import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/quote_model.dart';
import '../providers/quote_provider.dart';

class QuotesListScreen extends ConsumerWidget {
  final bool isProvider;

  const QuotesListScreen({super.key, this.isProvider = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = isProvider
        ? ref.watch(receivedQuotesProvider)
        : ref.watch(myQuotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isProvider ? 'Cotizaciones Recibidas' : 'Mis Cotizaciones'),
        centerTitle: true,
      ),
      body: quotesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (quotes) {
          if (quotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.request_quote_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    isProvider
                        ? 'No tienes cotizaciones recibidas'
                        : 'No has solicitado cotizaciones',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                  isProvider ? receivedQuotesProvider : myQuotesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quotes.length,
              itemBuilder: (context, index) =>
                  _QuoteTile(quote: quotes[index], isProvider: isProvider),
            ),
          );
        },
      ),
    );
  }
}

class _QuoteTile extends ConsumerStatefulWidget {
  final QuoteModel quote;
  final bool isProvider;

  const _QuoteTile({required this.quote, required this.isProvider});

  @override
  ConsumerState<_QuoteTile> createState() => _QuoteTileState();
}

class _QuoteTileState extends ConsumerState<_QuoteTile> {
  bool _offerLoading = false;

  void _showOfferDialog() {
    final priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ofertar Precio'),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Describe la cotización:'),
              const SizedBox(height: 4),
              Text(widget.quote.description,
                  maxLines: 3, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Precio propuesto (S/)',
                  prefixText: 'S/ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              priceController.dispose();
              Navigator.pop(ctx);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _offerLoading
                ? null
                : () async {
                    setState(() => _offerLoading = true);
                    final priceText = priceController.text.trim();
                    final price = double.tryParse(priceText);
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(ctx);

                    if (price == null || price <= 0) {
                      setState(() => _offerLoading = false);
                      return;
                    }
                    final ok = await ref
                        .read(quoteFormControllerProvider.notifier)
                        .respond(widget.quote.id, 'offered', price);
                    priceController.dispose();

                    if (!mounted) return;
                    navigator.pop();
                    if (ok) {
                      messenger.showSnackBar(
                        const SnackBar(
                            content: Text('Precio ofertado'),
                            backgroundColor: AppColors.success),
                      );
                    } else {
                      final error =
                          ref.read(quoteFormControllerProvider).error;
                      messenger.showSnackBar(
                        SnackBar(
                          content:
                              Text(error ?? 'Error al ofertar precio'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                    if (mounted) setState(() => _offerLoading = false);
                  },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: _offerLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Enviar Oferta'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAcceptDialog(BuildContext context) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    bool dialogLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Aceptar Cotización'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Precio: S/ ${widget.quote.proposedPrice!.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success),
              ),
              const SizedBox(height: 16),
              const Text('Selecciona la fecha y hora para el servicio:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 60)),
                        );
                        if (date != null) {
                          setDialogState(() => selectedDate = date);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(selectedTime.format(ctx)),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setDialogState(() => selectedTime = time);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: dialogLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: dialogLoading
                  ? null
                  : () async {
                      setDialogState(() => dialogLoading = true);
                      final startTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);

                      final ok = await ref
                          .read(quoteFormControllerProvider.notifier)
                          .respond(widget.quote.id, 'accepted', null,
                              startTime: startTime);

                      if (!mounted) return;
                      navigator.pop();
                      if (ok) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Cotización aceptada! Reserva creada.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        final error =
                            ref.read(quoteFormControllerProvider).error;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                                error ?? 'Error al aceptar cotización'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success),
              child: dialogLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Aceptar y Crear Reserva'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rejectQuote(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(quoteFormControllerProvider.notifier)
        .respond(widget.quote.id, 'declined', null);
    if (ok) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cotización rechazada'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusBadge(widget.quote.status),
                const Spacer(),
                Text(
                  widget.quote.createdAt != null
                      ? '${widget.quote.createdAt!.day}/${widget.quote.createdAt!.month}'
                      : '',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.quote.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            if (widget.quote.proposedPrice != null) ...[
              const SizedBox(height: 8),
              Text(
                'S/ ${widget.quote.proposedPrice!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
            if (widget.isProvider && widget.quote.status == 'requested') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Ofertar Precio',
                  isLoading: _offerLoading,
                  onPressed: _offerLoading
                      ? null
                      : _showOfferDialog,
                ),
              ),
            ],
            if (widget.isProvider && widget.quote.status == 'offered') ...[
              const SizedBox(height: 8),
              Text(
                'Esperando respuesta del cliente...',
                style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600),
              ),
            ],
            if (!widget.isProvider && widget.quote.status == 'offered') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, color: AppColors.error),
                      label: const Text('Rechazar',
                          style: TextStyle(color: AppColors.error)),
                      onPressed: () => _rejectQuote(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text('Aceptar'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success),
                      onPressed: () => _showAcceptDialog(context),
                    ),
                  ),
                ],
              ),
            ],
            if (!widget.isProvider && widget.quote.status == 'accepted') ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.success, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Aceptada — Reserva creada',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'requested':
        color = AppColors.primary;
        label = 'Solicitado';
      case 'offered':
        color = AppColors.warning;
        label = 'Ofertado';
      case 'accepted':
        color = AppColors.success;
        label = 'Aceptado';
      case 'declined':
        color = AppColors.error;
        label = 'Rechazado';
      case 'cancelled':
        color = Colors.grey;
        label = 'Cancelado';
      default:
        color = AppColors.primary;
        label = 'Solicitado';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
