import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../favorites/presentation/providers/favorite_provider.dart';
import '../../data/models/service_model.dart';

class ServiceCard extends ConsumerWidget {
  const ServiceCard({required this.service, super.key});

  final ServiceModel service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIdsAsync = ref.watch(favoriteIdsProvider);
    final favIds = favIdsAsync.asData?.value ?? [];
    final isFav = favIds.contains(service.id);

    return Card(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/services/detail', extra: service);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGEN DE PORTADA
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: service.images.isNotEmpty
                  ? Image.network(
                      service.images.first.url,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 130,
                        color: AppColors.primaryContainer.withValues(alpha: 0.5),
                        child: const Icon(Icons.broken_image, color: AppColors.primary, size: 32),
                      ),
                    )
                  : Container(
                      height: 130,
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      child: const Icon(Icons.image_not_supported, color: AppColors.primary, size: 32),
                    ),
            ),
            
            // 2. CONTENIDO DE LA TARJETA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título del Servicio
                  Text(
                    service.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15, 
                      color: AppColors.textPrimary
                    ),
                  ),
                  const SizedBox(height: 2),
                  
                  // Descripción corta
                  Text(
                    service.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12, 
                      color: AppColors.textSecondary
                    ),
                  ),
                  // Rating stars
                  if (service.averageRating != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          ...List.generate(5, (i) => Icon(
                            i < service.averageRating!.round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          )),
                          const SizedBox(width: 4),
                          Text(
                            service.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          if (service.reviewsCount > 0) ...[
                            const SizedBox(width: 2),
                            Text(
                              '(${service.reviewsCount})',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),

          // Fila superior: proveedor + corazon favorito
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/providers/${service.provider?.id ?? ''}'),
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: AppColors.primaryContainer,
                        backgroundImage: service.provider?.profilePictureUrl
                                    .isNotEmpty ==
                                true
                            ? NetworkImage(service.provider!.profilePictureUrl)
                            : null,
                        child: service.provider?.profilePictureUrl.isEmpty ==
                                    true ||
                                service.provider == null
                            ? const Icon(Icons.person,
                                size: 10, color: AppColors.primary)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        service.provider?.name ?? 'Profesional Toklen',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () async {
                  final success = await ref
                      .read(favoriteToggleControllerProvider.notifier)
                      .toggle(service.id, isFav);
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error al actualizar favorito'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: isFav ? AppColors.error : Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          const SizedBox(height: 0),
                  
                  // Fila de Precio y Categoría
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'S/ ${service.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900, // 🔥 Corregido para máxima compatibilidad web
                          fontSize: 15, 
                          color: AppColors.success
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          service.category?.name ?? 'General',
                          style: const TextStyle(
                            color: AppColors.primary, 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}