import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

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
                'Dashboard Administrativo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Visión general y métricas clave de TOKLEN',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              _buildStatsRow(context, s),

              const SizedBox(height: 32),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildChartCard('Actividad del Sistema', s),
                        const SizedBox(height: 24),
                        _buildActivityCard(s),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildTopServicesList(data.topServices),
                  ),
                ],
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

      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: cardWidth.clamp(180, 300),
            child: _statCard('Total Usuarios', '${s.totalUsers}',
                Icons.people_rounded, AppColors.primary, '${s.newUsers7d} nuevos (7d)'),
          ),
          SizedBox(
            width: cardWidth.clamp(180, 300),
            child: _statCard('Proveedores', '${s.totalProviders}',
                Icons.work_rounded, Colors.blue, '${s.verifiedProviders} verificados'),
          ),
          SizedBox(
            width: cardWidth.clamp(180, 300),
            child: _statCard('Servicios Activos', '${s.totalServices}',
                Icons.build_circle_rounded, AppColors.success, 'Publicados'),
          ),
          SizedBox(
            width: cardWidth.clamp(180, 300),
            child: _statCard('Ingresos Est.', 'S/ ${s.totalRevenue.toStringAsFixed(0)}',
                Icons.monetization_on_rounded, AppColors.warning, 'Completados'),
          ),
        ],
      );
    });
  }

  Widget _statCard(String label, String value, IconData icon, Color color, String sub) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, dynamic s) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (s.totalUsers > s.totalServices ? s.totalUsers : s.totalServices).toDouble() * 1.5,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = ['Usuarios', 'Provs', 'Servicios', 'Reservas'];
                          if (value < 0 || value >= titles.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(titles[value.toInt()], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: s.totalUsers.toDouble(), color: AppColors.primary, width: 22, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: s.totalProviders.toDouble(), color: Colors.blue, width: 22, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: s.totalServices.toDouble(), color: AppColors.success, width: 22, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: s.totalBookings.toDouble(), color: AppColors.warning, width: 22, borderRadius: BorderRadius.circular(4))]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(dynamic s) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Métricas de Rendimiento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            _activityRow('Tasa de Conversión', '${s.conversionRate.toStringAsFixed(1)}%', AppColors.primary),
            const Divider(height: 32),
            _activityRow('Usuarios Suspendidos', '${s.suspendedUsers}', AppColors.error),
            const Divider(height: 32),
            _activityRow('Solicitudes Pendientes', '${s.totalBookings}', AppColors.warning),
          ],
        ),
      ),
    );
  }

  Widget _activityRow(String label, String value, Color color) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTopServicesList(List<dynamic> topServices) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mejores Valorados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            if (topServices.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Sin datos disponibles', style: TextStyle(color: AppColors.textTertiary))))
            else
              ...topServices.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(service.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(service.providerName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${service.averageRating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.amber)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
