import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/services/presentation/screens/my_services_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/main_navigation_screen.dart';
import '../../features/services/data/models/service_model.dart';
import '../../features/services/presentation/screens/manage_service_screen.dart';
import '../../features/services/presentation/screens/service_detail_screen.dart';
import '../../features/services/presentation/screens/add_service_screen.dart';
import '../../features/services/presentation/screens/provider_profile_screen.dart';

// Importaciones de Admin
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';

final _splashRoute = GoRoute(
  path: '/splash',
  builder: (_, __) => const SplashScreen(),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',

    redirect: (context, state) {
      // Mientras auth se inicializa, mostrar splash
      if (authState.isLoading) {
        if (state.uri.path != '/splash') return '/splash';
        return null;
      }

      final isAuth = authState.value?.accessToken?.isNotEmpty ?? false;
      final userRole = authState.value?.user?.role ?? '';
      
      final isGoingToLogin = state.uri.path == '/login';
      final isGoingToRegister = state.uri.path == '/register';
      final isPublicRoute = isGoingToLogin || isGoingToRegister;
      final isSplash = state.uri.path == '/splash';

      // Si ya cargó auth y estamos en splash, redirigir según estado y ROL
      if (isSplash) {
        if (!isAuth) return '/login';
        
        // 🎯 NAVEGACIÓN BASADA EN ROL
        if (userRole == 'admin') return '/admin';
        return '/home'; // Cliente o Proveedor
      }

      // Si NO está autenticado y quiere acceder a rutas privadas
      if (!isAuth && !isPublicRoute) {
        return '/login';
      }

      // Si SÍ está autenticado y quiere ir al login/register
      if (isAuth && isPublicRoute) {
        // Redirigir según su rol
        if (userRole == 'admin') return '/admin';
        return '/home';
      }

      // 🛡️ PROTECCIÓN: Admin no puede acceder a rutas de cliente/proveedor
      if (isAuth && userRole == 'admin') {
        final isAdminRoute = state.uri.path.startsWith('/admin');
        if (!isAdminRoute && state.uri.path != '/splash') {
          return '/admin'; // Forzar a quedarse en admin
        }
      }

      // 🛡️ PROTECCIÓN: Cliente/Proveedor no puede acceder a rutas de admin
      if (isAuth && userRole != 'admin') {
        final isAdminRoute = state.uri.path.startsWith('/admin');
        if (isAdminRoute) {
          return '/home'; // Forzar a quedarse en app normal
        }
      }

      return null;
    },

    routes: [
      _splashRoute,
      
      // RUTAS PÚBLICAS
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // 🎯 RUTA EXCLUSIVA PARA ADMINISTRADOR
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      
      // RUTAS PARA CLIENTE Y PROVEEDOR
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/services/create',
        builder: (context, state) => const AddServiceScreen(),
      ),
      GoRoute(
        path: '/my-services',
        builder: (context, state) => const MyServicesScreen(),
      ),
      GoRoute(
        path: '/services/detail',
        builder: (context, state) {
          if (state.extra is! ServiceModel) {
            return Scaffold(
              appBar: AppBar(title: const Text('Servicio no encontrado')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('La sesión web se refrescó y se perdió el dato.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Volver al Catálogo'),
                    )
                  ],
                ),
              ),
            );
          }
          final service = state.extra as ServiceModel;
          return ServiceDetailScreen(service: service);
        },
      ),
      GoRoute(
        path: '/providers/:providerId',
        builder: (context, state) => ProviderProfileScreen(providerId: state.pathParameters['providerId']!),
      ),
      GoRoute(
        path: '/services/manage',
        builder: (context, state) {
          if (state.extra is! ServiceModel) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error de carga')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No se puede gestionar el servicio en este momento.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Volver al Catálogo'),
                    )
                  ],
                ),
              ),
            );
          }
          final service = state.extra as ServiceModel;
          return ManageServiceScreen(service: service);
        },
      ),
    ],
  );
});
