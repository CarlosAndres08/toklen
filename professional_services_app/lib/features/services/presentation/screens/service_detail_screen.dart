import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
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
    final String userRole = authState?.user?.role ?? 'client';
    
    final bool isOwner = userRole == 'provider' && currentUserId == currentService.provider?.id;
    final double screenWidth = MediaQuery.of(context).size.width;
    final reviewsAsync = ref.watch(serviceReviewsProvider(currentService.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle del Servicio', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
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
                        height: MediaQuery.of(context).size.width > 600 ? 400 : 250, 
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
                          left: 8,
                          child: IconButton(
                            onPressed: _previousImage,
                            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                            style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.4), padding: const EdgeInsets.all(8)),
                          ),
                        ),

                      if (currentService.images.length > 1 && _currentImageIndex < currentService.images.length - 1)
                        Positioned(
                          right: 8,
                          child: IconButton(
                            onPressed: () => _nextImage(currentService.images.length),
                            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
                            style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.4), padding: const EdgeInsets.all(8)),
                          ),
                        ),

                      if (currentService.images.length > 1)
                        Positioned(
                          top: 16, right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)),
                            child: Text('${_currentImageIndex + 1} / ${currentService.images.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity, height: 220, color: AppColors.primaryContainer,
                    child: const Center(child: Icon(Icons.image_outlined, size: 64, color: AppColors.primary)),
                  ),
                
                // 2. CONTENIDO PRINCIPAL
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                        child: Text(currentService.category?.name ?? 'Sin categoría', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(height: 16),
                      
                      Text(currentService.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      
                      Text('S/ ${currentService.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.success)),
                      const SizedBox(height: 24),
                      
                      const Text('Ofrecido por', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 24, backgroundColor: AppColors.primaryContainer,
                          backgroundImage: currentService.provider?.profilePictureUrl.isNotEmpty == true ? NetworkImage(currentService.provider!.profilePictureUrl) : null,
                          child: currentService.provider?.profilePictureUrl.isEmpty == true ? const Icon(Icons.person, color: AppColors.primary) : null,
                        ),
                        title: Row(
                          children: [
                            Text(currentService.provider?.name ?? 'Usuario Anónimo', style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (currentService.provider?.isVerified == true) ...[
                              const SizedBox(width: 4), const Icon(Icons.verified, size: 18, color: AppColors.primary),
                            ]
                          ],
                        ),
                        subtitle: const Text('Profesional en TOKLEN'),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      
                      const Text('Descripción del servicio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      Text(currentService.description, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 24),
                      const Text('Reseñas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      reviewsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        error: (_, __) => const Text('No se pudieron cargar las reseñas.', style: TextStyle(color: AppColors.textSecondary)),
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return const Text('Aún no hay reseñas para este servicio.', style: TextStyle(color: AppColors.textSecondary));
                          }
                          return Column(
                            children: reviews.map((r) => ReviewCard(review: r)).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      
      // 3. BARRA INFERIOR DE ACCIÓN (ESTRUCTURA SEGURA PARA EVITAR CONFLICTOS DE ALTURA)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 800),
                width: screenWidth > 832 ? 800 : screenWidth - 32,
                child: isOwner
                    ? PrimaryButton(
                        label: 'Gestionar mi servicio',
                        icon: Icons.edit,
                        onPressed: () {
                          context.push('/services/manage', extra: currentService);
                        },
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Reservar',
                              icon: Icons.calendar_today,
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
                          const SizedBox(width: 8),
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
                              icon: const Icon(Icons.request_quote_outlined,
                                  color: AppColors.primary),
                              label: const Text('Cotizar',
                                  style: TextStyle(color: AppColors.primary)),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}