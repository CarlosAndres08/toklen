import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../services/presentation/screens/services_by_category_screen.dart';
import '../../../services/presentation/providers/service_provider.dart';
import '../../../services/data/models/service_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/category_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final featuredAsync = ref.watch(featuredServicesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Explorar'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoryListProvider);
          ref.invalidate(featuredServicesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Sección de Destacados con Skeleton
            featuredAsync.when(
              loading: () => _buildFeaturedSkeleton(),
              error: (error, stack) => const SizedBox.shrink(),
              data: (featured) {
                if (featured.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Destacados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 190,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: featured.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 16),
                        itemBuilder: (context, index) => _FeaturedCard(service: featured[index]),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),

            const Text('Categorías', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 16),

            // Sección de Categorías con Skeleton y Empty State
            categoriesAsync.when(
              loading: () => _buildCategoriesSkeleton(),
              error: (error, stack) => Center(
                child: EmptyState(
                  title: 'Error de carga',
                  message: error.toString(),
                  icon: Icons.error_outline,
                  actionLabel: 'Reintentar',
                  onActionPressed: () => ref.read(categoryListProvider.notifier).refresh(),
                ),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return const EmptyState(
                    title: 'No hay categorías',
                    message: 'Vuelve más tarde para descubrir nuevos servicios.',
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Card(
                      child: InkWell(
                        onTap: () {
                          ref.read(serviceListProvider.notifier).filterByCategory(category.id);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ServicesByCategoryScreen(categoryName: category.name ?? 'Servicios'),
                          ));
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.category, color: AppColors.primary, size: 28),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                category.name ?? 'Sin nombre',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLoader(width: 120, height: 20),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) => const SkeletonLoader(width: 180, height: 180, borderRadius: 16),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCategoriesSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const SkeletonLoader(width: double.infinity, height: 150, borderRadius: 16),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.service});
  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/services/detail', extra: service),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: service.images.isNotEmpty
                  ? Image.network(service.images.first.url, height: 100, width: 200, fit: BoxFit.cover)
                  : Container(height: 100, color: AppColors.primaryContainer, child: const Icon(Icons.image, color: AppColors.primary)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(service.provider?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('S/ ${service.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.success)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
