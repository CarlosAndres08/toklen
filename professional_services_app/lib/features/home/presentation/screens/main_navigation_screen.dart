import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookings/presentation/screens/booking_requests_screen.dart';
import '../../../bookings/presentation/screens/my_bookings_screen.dart';
import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Obtener el rol del usuario para determinar qué pantalla mostrar en Reservas
    final String userRole =
        ref.watch(authControllerProvider).value?.user?.rol ?? 'client';

    // 📦 Inyectamos las pantallas reales en las pestañas según el rol
    final List<Widget> screens = [
      const CategoriesScreen(), // 🔥 Pestaña 0: Tu Catálogo Real
      // Pestaña 1: Reservas (diferente pantalla según el rol)
      userRole == 'provider'
          ? const BookingRequestsScreen() // Vista de proveedor
          : const MyBookingsScreen(), // Vista de cliente
      const ChatListScreen(),
      const ProfileScreen(), // 🔥 Pestaña 3: Tu Perfil Real
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: AppColors.primary),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary),
            label: 'Reservas',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat, color: AppColors.primary),
            label: 'Mensajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// 🛠️ Widget temporal (Lo dejamos para Reservas y Mensajes)
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderScreen({required this.title, required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Pantalla de $title en construcción', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}