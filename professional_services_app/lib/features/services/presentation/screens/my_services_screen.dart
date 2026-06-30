import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/service_provider.dart';

class MyServicesScreen extends ConsumerWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider).value;
    final currentUserId = authState?.user?.id ?? '';
    final user = authState?.user;
    final isAvailable = user?.isAvailable ?? true;
    final servicesAsync = ref.watch(serviceListProvider);
    final toggleAsync = ref.watch(availabilityToggleControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Publicaciones', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isAvailable ? 'Disponible' : 'Ocupado', style: TextStyle(fontSize: 12, color: isAvailable ? AppColors.success : Colors.grey)),
                Switch(
                  value: isAvailable,
                  activeColor: AppColors.success,
                  onChanged: toggleAsync.isLoading
                      ? null
                      : (_) => ref.read(availabilityToggleControllerProvider.notifier).toggle(),
                ),
              ],
            ),
          ),
        ],
      ),
      // Botón flotante para crear más servicios rápido
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/services/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.onPrimary),
        label: const Text('Nuevo Servicio', style: TextStyle(color: AppColors.onPrimary)),
      ),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (allServices) {
          // 🔥 FILTRO MAGNÍFICO: Solo mostramos los servicios de ESTE proveedor
          final myServices = allServices.where((s) => s.provider?.id == currentUserId).toList();

          if (myServices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront_outlined, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('Aún no tienes servicios.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('Publica tu primer servicio y llega a más clientes.', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          // Lista de los servicios del proveedor
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: myServices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final service = myServices[index];
              // Asumimos que tu modelo tiene un boolean isActive. Si no lo tiene, temporalmente simulamos que es true
              // final bool isActive = service.isActive ?? true;
              final bool isActive = true; // 🔥 Reemplaza con service.isActive si ya existe en tu modelo

              return Card(
                color: AppColors.surface,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // 1. Imagen miniatura
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: service.images.isNotEmpty
                            ? Image.network(service.images.first.url, height: 70, width: 70, fit: BoxFit.cover)
                            : Container(height: 70, width: 70, color: AppColors.primaryContainer, child: const Icon(Icons.image, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 12),
                      
                      // 2. Información
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(service.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('S/ ${service.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            // Etiqueta visual de estado
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isActive ? 'ACTIVO' : 'INACTIVO',
                                style: TextStyle(color: isActive ? AppColors.success : AppColors.error, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 3. Controles (Switch y Editar)
                      Column(
                        children: [
                          Switch(
                            value: isActive,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              // 🔥 AQUÍ VA TU LÓGICA DE ACTIVAR/DESACTIVAR
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cambiando estado a ${value ? "Activo" : "Inactivo"}...')));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                            onPressed: () {
                              context.push('/services/manage', extra: service);
                            },
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}