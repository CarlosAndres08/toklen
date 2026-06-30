import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/admin_provider.dart';

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminDashboardProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (data) {
          final s = data.summary;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Panel de Administraci\u00f3n',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Resumen general del sistema TOKLEN',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              _buildStatsRow(context, s),
              const SizedBox(height: 32),
              const Text(
                'Top Servicios',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (data.topServices.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No hay servicios con suficientes rese\u00f1as',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                ...data.topServices.map(
                  (service) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.amber.withValues(alpha: 0.15),
                        child: const Icon(Icons.star, color: Colors.amber),
                      ),
                      title: Text(service.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(service.providerName),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${service.averageRating.toStringAsFixed(1)} \u2605',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, dynamic s) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 900;
      final cardWidth = isWide ? (constraints.maxWidth - 48) / 4 : constraints.maxWidth;

      return Column(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: cardWidth.clamp(180, 300),
                child: _statCard('Total Usuarios', '${s.totalUsers}',
                    Icons.people, AppColors.primary, '${s.newUsers7d} nuevos (7d)'),
              ),
              SizedBox(
                width: cardWidth.clamp(180, 300),
                child: _statCard('Proveedores', '${s.totalProviders}',
                    Icons.work, Colors.blue, '${s.verifiedProviders} verificados'),
              ),
              SizedBox(
                width: cardWidth.clamp(180, 300),
                child: _statCard('Servicios', '${s.totalServices}',
                    Icons.build, AppColors.info, 'Publicados'),
              ),
              SizedBox(
                width: cardWidth.clamp(180, 300),
                child: _statCard('Reservas', '${s.totalBookings}',
                    Icons.calendar_today, AppColors.warning, 'Totales'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: cardWidth.clamp(180, 300),
                child: _statCard('Ingresos Totales',
                    '\$${s.totalRevenue.toStringAsFixed(0)}',
                    Icons.attach_money, AppColors.success, 'Completados'),
              ),
              SizedBox(
                width: cardWidth.clamp(180, 300),
                child: _statCard('Tasa de Conversi\u00f3n',
                    '${s.conversionRate.toStringAsFixed(1)}%',
                    Icons.trending_up, AppColors.secondary, 'Reservas completadas'),
              ),
              SizedBox(
                width: cardWidth.clamp(180, 300),
                child: _statCard('Nuevos (7d)', '${s.newUsers7d}',
                    Icons.person_add, AppColors.info, '\u00daltimos 7 d\u00edas'),
              ),
              SizedBox(
                width: cardWidth.clamp(180, 300),
                child: _statCard('Suspendidos', '${s.suspendedUsers}',
                    Icons.block, Colors.red, 'Usuarios'),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color, String sub) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
