import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../providers/user_management_provider.dart';
import '../providers/provider_verification_provider.dart';

class AdminProvidersScreen extends ConsumerStatefulWidget {
  const AdminProvidersScreen({super.key});

  @override
  ConsumerState<AdminProvidersScreen> createState() =>
      _AdminProvidersScreenState();
}

class _AdminProvidersScreenState extends ConsumerState<AdminProvidersScreen> {
  @override
  Widget build(BuildContext context) {
    const params = UserListParams(rol: 'provider', pageSize: 100);
    final providersAsync = ref.watch(userListProvider(params));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: providersAsync.when(
              loading: () => _buildSkeleton(),
              error: (e, _) => EmptyState(
                title: 'Error al cargar proveedores',
                message: e.toString(),
                icon: Icons.error_outline,
                actionLabel: 'Reintentar',
                onActionPressed: () => ref.invalidate(userListProvider(params)),
              ),
              data: (providers) {
                if (providers.isEmpty) {
                  return const EmptyState(
                    title: 'Sin proveedores',
                    message: 'No hay proveedores registrados en el sistema.',
                    icon: Icons.work_off_outlined,
                  );
                }

                final verifiedCount = providers.where((u) => u['is_verified'] == true).length;
                final pendingCount = providers.where((u) => u['is_verified'] != true).length;

                return Column(
                  children: [
                    _buildStatsBar(providers.length, verifiedCount, pendingCount),
                    const SizedBox(height: 24),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(userListProvider(params));
                          ref.invalidate(pendingVerificationsProvider);
                        },
                        child: _buildTableOrList(providers),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Icon(Icons.work_rounded, color: AppColors.primary, size: 32),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestión de Proveedores',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
              ),
              Text(
                'Administra y verifica la identidad de los profesionales',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          IconButton.filledTonal(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(userListProvider(const UserListParams(rol: 'provider', pageSize: 100)));
              ref.invalidate(pendingVerificationsProvider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(int total, int verified, int pending) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _statMiniCard('Total', total.toString(), AppColors.primary),
          const SizedBox(width: 16),
          _statMiniCard('Verificados', verified.toString(), Colors.green),
          const SizedBox(width: 16),
          _statMiniCard('Pendientes', pending.toString(), Colors.orange),
        ],
      ),
    );
  }

  Widget _statMiniCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTableOrList(List<dynamic> providers) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 800) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: providers.length,
          itemBuilder: (context, index) => _buildProviderMobileCard(providers[index]),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DataTable(
            headingRowHeight: 56,
            dataRowMaxHeight: 72,
            dividerThickness: 1,
            columns: const [
              DataColumn(label: Text('Proveedor', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Servicios', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.w700))),
            ],
            rows: providers.map((p) => _buildProviderRow(p)).toList(),
          ),
        ),
      );
    });
  }

  DataRow _buildProviderRow(Map<String, dynamic> provider) {
    final name = provider['nombre']?.toString() ?? provider['name']?.toString() ?? 'Profesional';
    final isVerified = provider['is_verified'] == true;

    return DataRow(
      cells: [
        DataCell(Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryContainer,
              child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        )),
        DataCell(Text(provider['email']?.toString() ?? '-')),
        DataCell(_buildStatusBadge(isVerified)),
        DataCell(Text('${provider['total_services'] ?? 0}')),
        DataCell(Row(
          children: [
            if (!isVerified)
              IconButton(
                onPressed: () => _showVerifyDialog(provider),
                icon: const Icon(Icons.verified_user_rounded, color: Colors.green),
                tooltip: 'Verificar',
              ),
            IconButton(
              onPressed: () => _confirmDelete(provider),
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildStatusBadge(bool verified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: verified ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        verified ? 'VERIFICADO' : 'PENDIENTE',
        style: TextStyle(color: verified ? Colors.green : Colors.orange, fontWeight: FontWeight.w800, fontSize: 10),
      ),
    );
  }

  Widget _buildProviderMobileCard(Map<String, dynamic> provider) {
    final name = provider['nombre']?.toString() ?? provider['name']?.toString() ?? 'Profesional';
    final isVerified = provider['is_verified'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider['email']?.toString() ?? ''),
            const SizedBox(height: 8),
            _buildStatusBadge(isVerified),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (!isVerified) const PopupMenuItem(value: 'verify', child: Text('Verificar')),
            const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: AppColors.error))),
          ],
          onSelected: (val) {
            if (val == 'verify') _showVerifyDialog(provider);
            if (val == 'delete') _confirmDelete(provider);
          },
        ),
      ),
    );
  }

  void _showVerifyDialog(Map<String, dynamic> provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verificar Proveedor'),
        content: Text('¿Deseas aprobar la verificación de identidad para ${provider['nombre'] ?? provider['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              final ok = await ref.read(verificationControllerProvider).approveVerification(provider['id'].toString());
              if (!mounted) return;

              navigator.pop();
              if (ok) {
                ref.invalidate(userListProvider(const UserListParams(rol: 'provider', pageSize: 100)));
                    messenger.showSnackBar(const SnackBar(content: Text('Proveedor verificado correctamente'), backgroundColor: Colors.green));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Aprobar'),
          ),
          OutlinedButton(
            onPressed: () => _showRejectDialog(provider, ctx),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> provider, BuildContext verifyCtx) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Verificación'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Motivo del rechazo', hintText: 'Ej. Documento ilegible'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              final verifyNavigator = Navigator.of(verifyCtx);

              final ok = await ref.read(verificationControllerProvider).rejectVerification(provider['id'].toString(), reasonController.text);
              if (!mounted) return;

              navigator.pop();
              verifyNavigator.pop();
              if (ok) {
                ref.invalidate(userListProvider(const UserListParams(rol: 'provider', pageSize: 100)));
                messenger.showSnackBar(const SnackBar(content: Text('Verificación rechazada'), backgroundColor: AppColors.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Proveedor'),
        content: const Text('¿Estás seguro? Esta acción eliminará al proveedor y todos sus servicios permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);

              final ok = await ref.read(userManagementControllerProvider).deleteUser(provider['id'].toString());
              if (!mounted) return;

              navigator.pop();
              if (ok) {
                ref.invalidate(userListProvider(const UserListParams(rol: 'provider', pageSize: 100)));
                messenger.showSnackBar(const SnackBar(content: Text('Proveedor eliminado')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(5, (index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(width: double.infinity, height: 60, borderRadius: 12),
        )),
      ),
    );
  }
}
