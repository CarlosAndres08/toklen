import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/admin_sidebar.dart';
import 'admin_overview_screen.dart';
import 'admin_users_screen.dart';
import 'admin_providers_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_services_screen.dart';
import 'admin_settings_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    AdminOverviewScreen(),
    AdminUsersScreen(),
    AdminProvidersScreen(),
    AdminCategoriesScreen(),
    AdminServicesScreen(),
    AdminSettingsScreen(),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Usuarios',
    'Proveedores',
    'Categor\u00edas',
    'Servicios',
    'Configuraci\u00f3n',
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isMobile
          ? AppBar(
              title: Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppColors.surface,
              elevation: 0,
              scrolledUnderElevation: 1,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: AdminSidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!isMobile)
              SizedBox(
                width: 280,
                child: AdminSidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                ),
              ),
            if (!isMobile)
              const VerticalDivider(width: 1, color: AppColors.border),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
