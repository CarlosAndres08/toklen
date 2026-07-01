import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/admin_provider.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(adminProfileProvider);
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuraci\u00f3n del Sistema',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Informaci\u00f3n del administrador y estad\u00edsticas',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          profileAsync.when(
            data: (profile) => _buildSection(
              title: 'Perfil del Administrador',
              icon: Icons.admin_panel_settings,
              child: Column(
                children: [
                  _buildProfileRow(Icons.person, 'Nombre', profile.name),
                  if (profile.apellido != null && profile.apellido!.isNotEmpty)
                    _buildProfileRow(
                        Icons.person_outline, 'Apellido', profile.apellido!),
                  _buildProfileRow(Icons.email, 'Email', profile.email),
                  _buildProfileRow(Icons.badge, 'Rol',
                      profile.role.isEmpty ? 'Administrador' : profile.role),
                  if (profile.phone != null && profile.phone!.isNotEmpty)
                    _buildProfileRow(
                        Icons.phone, 'Tel\u00e9fono', profile.phone!),
                ],
              ),
            ),
            loading: () => _buildSection(
              title: 'Perfil del Administrador',
              icon: Icons.admin_panel_settings,
              child: const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )),
            ),
            error: (e, _) => _buildSection(
              title: 'Perfil del Administrador',
              icon: Icons.admin_panel_settings,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error al cargar perfil: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          dashboardAsync.when(
            data: (data) => _buildSection(
              title: 'Estad\u00edsticas del Sistema',
              icon: Icons.bar_chart,
              child: Column(
                children: [
                  _buildStatRow('Total Usuarios', '${data.summary.totalUsers}'),
                  _buildStatRow(
                      'Total Proveedores', '${data.summary.totalProviders}'),
                  _buildStatRow(
                      'Total Servicios', '${data.summary.totalServices}'),
                  _buildStatRow(
                      'Total Reservas', '${data.summary.totalBookings}'),
                  _buildStatRow('Ingresos Totales',
                      '\$${data.summary.totalRevenue.toStringAsFixed(0)}'),
                  _buildStatRow('Usuarios Nuevos (7d)',
                      '${data.summary.newUsers7d}'),
                  _buildStatRow('Tasa de Conversi\u00f3n',
                      '${data.summary.conversionRate.toStringAsFixed(1)}%'),
                ],
              ),
            ),
            loading: () => _buildSection(
              title: 'Estad\u00edsticas del Sistema',
              icon: Icons.bar_chart,
              child: const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          _buildSection(
            title: 'Informaci\u00f3n',
            icon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileRow(
                    Icons.info, 'Plataforma', 'TOKLEN - Professional Services'),
                _buildProfileRow(Icons.language, 'Idioma', 'Espa\u00f1ol'),
                _buildProfileRow(Icons.verified_user, 'Estado', 'Sistema activo'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
