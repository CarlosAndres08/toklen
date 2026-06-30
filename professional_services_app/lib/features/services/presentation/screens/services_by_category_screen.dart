import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/service_provider.dart';
import '../widgets/service_card.dart';

class ServicesByCategoryScreen extends ConsumerStatefulWidget {
  const ServicesByCategoryScreen({
    required this.categoryName,
    super.key,
  });

  final String categoryName;

  @override
  ConsumerState<ServicesByCategoryScreen> createState() =>
      _ServicesByCategoryScreenState();
}

class _ServicesByCategoryScreenState
    extends ConsumerState<ServicesByCategoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(serviceListProvider);
    final authState = ref.watch(authControllerProvider).value;
    final String userRole = authState?.user?.role ?? 'client';
    final bool isProvider = userRole == 'provider';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.categoryName,
            style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      floatingActionButton: isProvider
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push('/services/create');
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: AppColors.onPrimary),
              label: const Text('Crear Servicio',
                  style: TextStyle(color: AppColors.onPrimary)),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar servicios...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(serviceListProvider.notifier)
                              .search(null);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              onChanged: (value) {
                setState(() {});
                ref
                    .read(serviceListProvider.notifier)
                    .search(value.trim().isEmpty ? null : value.trim());
              },
            ),
          ),
          Expanded(
            child: servicesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image_outlined,
                          color: AppColors.error, size: 64),
                      const SizedBox(height: 16),
                      Text('Error al cargar: $error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ),
              data: (services) {
                if (services.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'No hay servicios.',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 300,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return ServiceCard(service: service);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}