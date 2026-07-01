import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookings/presentation/screens/create_booking_screen.dart';
import '../../../quotes/presentation/screens/request_quote_screen.dart';
import '../../../reviews/presentation/providers/review_provider.dart';
import '../../../reviews/presentation/widgets/review_card.dart';
import '../../data/models/service_model.dart';
import '../providers/service_provider.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  const ServiceDetailScreen({
    required this.service,
    super.key,
  });

  final ServiceModel service;

  @override
  ConsumerState<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController(); 

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextImage(int maxImages) {
    if (_currentImageIndex < maxImages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceListState = ref.watch(serviceListProvider);
    final currentService = serviceListState.value?.firstWhere(
      (s) => s.id == widget.service.id,
      orElse: () => widget.service,
    ) ?? widget.service;

    final authState = ref.watch(authControllerProvider).value;
    final String currentUserId = authState?.user?.id ?? '';
    final String userRole = authState?.user?.rol ?? 'client';
    
    final bool isOwner = userRole == 'provider' && currentUserId == currentService.provider?.id;
    final reviewsAsync = ref.watch(serviceReviewsProvider(currentService.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle del Servicio'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ZONA DE GALERÍA
                if (currentService.images.isNotEmpty)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.width > 600 ? 400 : 300,
                        width: double.infinity,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: currentService.images.length,
                          onPageChanged: (index) => setState(() => _currentImageIndex = index),
                          itemBuilder: (context, index) {
                            return Image.network(
                              currentService.images[index].url, 
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      
                      if (currentService.images.length > 1 && _currentImageIndex > 0)
                        Positioned(
                          left: 16,
                          child: IconButton(
                            onPressed: _previousImage,
                            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                            style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.3), padding: const EdgeInsets.all(12)),
                          ),
                        ),

                      if (currentService.images.length > 1 && _currentImageIndex < currentService.images.length - 1)
                        Positioned(
                          right: 16,
                          child: IconButton(
                            onPressed: () => _nextImage(currentService.images.length),
                            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                            style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.3), padding: const EdgeInsets.all(12)),
                          ),
                        ),

                      if (currentService.images.length > 1)
                        Positioned(
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(currentService.images.length, (index) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.4),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity, height: 300, color: AppColors.primaryContainer,
                    child: const Center(child: Icon(Icons.image_outlined, size: 64, color: AppColors.primary)),
                  ),
                
                // 2. CONTENIDO PRINCIPAL
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(10)),
                            child: Text(currentService.category?.name ?? 'General', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const Spacer(),
                          if (currentService.averageRating != null)
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(currentService.averageRating!.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(' (${currentService.reviewsCount})', style: const TextStyle(color: AppColors.textTertiary, fontSize: 14)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Text(currentService.title, style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 8),
                      
                      Text('S/ ${currentService.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.success)),
                      const SizedBox(height: 32),
                      
                      const Text('Ofrecido por', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28, backgroundColor: AppColors.primaryContainer,
                              backgroundImage: currentService.provider?.profilePictureUrl.isNotEmpty == true ? NetworkImage(currentService.provider!.profilePictureUrl) : null,
                              child: (currentService.provider?.profilePictureUrl ?? '').isEmpty ? const Icon(Icons.person, color: AppColors.primary, size: 30) : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(currentService.provider?.nombre ?? 'Profesional', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      if (currentService.provider?.isVerified == true) ...[
                                        const SizedBox(width: 6), const Icon(Icons.verified, size: 18, color: AppColors.primary),
                                      ]
                                    ],
                                  ),
                                  const Text('Profesional verificado en TOKLEN', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => context.push('/providers/${currentService.provider?.id}'),
                              icon: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      const Text('Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      Text(currentService.description, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6)),

                      const SizedBox(height: 40),
                      const Divider(),
                      const SizedBox(height: 32),

                      const Text('Reseñas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const SizedBox(height: 20),
                      reviewsAsync.when(
                        loading: () => Column(
                          children: List.generate(2, (index) => const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: 16),
                          )),
                        ),
                        error: (_, __) => const Text('No se pudieron cargar las reseñas.', style: TextStyle(color: AppColors.textSecondary)),
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(16)),
                              child: const Center(child: Text('Aún no hay reseñas.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
                            );
                          }
                          return Column(
                            children: reviews
                                .map((r) => ReviewCard(
                                      review: r,
                                      serviceId: currentService.id,
                                      providerId:
                                          currentService.provider?.id ?? '',
                                    ))
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: isOwner
                ? PrimaryButton(
                    label: 'Gestionar mi servicio',
                    icon: Icons.edit_note_rounded,
                    onPressed: () {
                      context.push('/services/manage', extra: currentService);
                    },
                  )
                : Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Reservar',
                          icon: Icons.calendar_today_rounded,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CreateBookingScreen(
                                  service: currentService,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => RequestQuoteScreen(
                                  serviceId: currentService.id,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.request_quote_rounded),
                          label: const Text('Cotizar'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 54),
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
