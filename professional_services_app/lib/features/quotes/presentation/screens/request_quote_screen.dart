import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/quote_provider.dart';

class RequestQuoteScreen extends ConsumerStatefulWidget {
  final String serviceId;

  const RequestQuoteScreen({super.key, required this.serviceId});

  @override
  ConsumerState<RequestQuoteScreen> createState() => _RequestQuoteScreenState();
}

class _RequestQuoteScreenState extends ConsumerState<RequestQuoteScreen> {
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quoteFormControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Cotización'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.request_quote_outlined,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Describe lo que necesitas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'El proveedor revisará tu solicitud y te responderá con un presupuesto.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Descripción del trabajo',
                hintText:
                    'Ej: Necesito reparar una tubería de agua caliente...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Enviar Solicitud',
              isLoading: state.isLoading,
              onPressed: () async {
                final desc = _descriptionController.text.trim();
                if (desc.length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Describe tu necesidad (mín. 10 caracteres)')),
                  );
                  return;
                }
                final ok = await ref
                    .read(quoteFormControllerProvider.notifier)
                    .create(widget.serviceId, desc);
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Cotización enviada exitosamente'),
                        backgroundColor: AppColors.success),
                  );
                  Navigator.pop(context);
                } else if (mounted) {
                  final error =
                      ref.read(quoteFormControllerProvider).error;
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
