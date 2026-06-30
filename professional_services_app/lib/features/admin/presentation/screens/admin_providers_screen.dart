import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
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
    final params = const UserListParams(rol: 'provider', pageSize: 100);
    final providersAsync = ref.watch(userListProvider(params));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          providersAsync.when(
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
                    onPressed: () => ref.invalidate(userListProvider(params)),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
            data: (providers) {
              final verifiedCount =
                  providers.where((u) => u['is_verified'] == true).length;
              final pendingCount =
                  providers.where((u) => u['is_verified'] != true).length;

              return Column(
                children: [
                  _buildStatsBar(
                      providers.length, verifiedCount, pendingCount),
                  const SizedBox(height: 8),
                  Expanded(
                    child: providers.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.work_outline,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No hay proveedores registrados',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async =>
                                ref.invalidate(userListProvider(params)),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth < 700) {
                                  return ListView.builder(
                                    padding:
                                        const EdgeInsets.only(bottom: 16),
                                    itemCount: providers.length,
                                    itemBuilder: (context, index) {
                                      final provider =
                                          providers[index]
                                              as Map<String, dynamic>;
                                      return _buildProviderCard(provider);
                                    },
                                  );
                                }
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor:
                                        WidgetStateProperty.all(
                                            AppColors.surface),
                                     dataRowMinHeight: 48,
                                     dataRowMaxHeight: 72,
                                    columnSpacing: 24,
                                    columns: const [
                                      DataColumn(label: Text('Avatar')),
                                      DataColumn(label: Text('Nombre')),
                                      DataColumn(label: Text('Email')),
                                      DataColumn(label: Text('Verificado')),
                                      DataColumn(label: Text('Documentos')),
                                      DataColumn(
                                          label: Text('Total Servicios')),
                                      DataColumn(label: Text('Acciones')),
                                    ],
                                    rows: providers.map((p) {
                                      final provider =
                                          p as Map<String, dynamic>;
                                      return _buildProviderRow(provider);
                                    }).toList(),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          const Icon(Icons.work, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gesti\u00f3n de Proveedores',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Administra y verifica proveedores',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userListProvider(
                  const UserListParams(rol: 'provider', pageSize: 100)));
              ref.invalidate(pendingVerificationsProvider);
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(int total, int verified, int pending) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Total', total.toString(), AppColors.primary),
          Container(
              width: 1, height: 32, color: AppColors.border),
          _statItem('Verificados', verified.toString(), Colors.green),
          Container(
              width: 1, height: 32, color: AppColors.border),
          _statItem('Pendientes', pending.toString(), Colors.orange),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  DataRow _buildProviderRow(Map<String, dynamic> provider) {
    final name =
        provider['name']?.toString() ?? provider['nombre']?.toString() ?? '';
    final email = provider['email']?.toString() ?? '';
    final isVerified = provider['is_verified'] == true;
    final documents = provider['documents'] as List<dynamic>? ?? [];
    final totalServices = provider['total_services'] as int? ?? 0;

    return DataRow(
      cells: [
        DataCell(
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'P',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        ),
        DataCell(Text(name,
            style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(email, style: const TextStyle(fontSize: 13))),
        DataCell(
          isVerified
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('S\u00ed',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('No',
                      style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
        ),
        DataCell(Text('${documents.length} docs')),
        DataCell(Text('$totalServices')),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isVerified)
              IconButton(
                onPressed: () => _approveVerification(provider),
                icon: const Icon(Icons.verified_outlined,
                    color: Colors.green, size: 20),
                tooltip: 'Aprobar verificaci\u00f3n',
                visualDensity: VisualDensity.compact,
              ),
            IconButton(
              onPressed: () => _showEditDialog(provider),
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.primary, size: 20),
              tooltip: 'Editar',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: () => _confirmDelete(provider),
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              tooltip: 'Eliminar',
              visualDensity: VisualDensity.compact,
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final name =
        provider['name']?.toString() ?? provider['nombre']?.toString() ?? '';
    final email = provider['email']?.toString() ?? '';
    final isVerified = provider['is_verified'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'P',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(email,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isVerified ? 'VERIFICADO' : 'PENDIENTE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isVerified ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (v) {
                if (v == 'verify' && !isVerified) {
                  _approveVerification(provider);
                }
                if (v == 'edit') _showEditDialog(provider);
                if (v == 'delete') _confirmDelete(provider);
              },
              itemBuilder: (_) => [
                if (!isVerified)
                  const PopupMenuItem(
                      value: 'verify', child: Text('Verificar')),
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Eliminar',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _approveVerification(Map<String, dynamic> provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Aprobar Verificaci\u00f3n'),
        content: Text(
            '\u00bfAprobar la verificaci\u00f3n de "${provider['name'] ?? provider['nombre'] ?? ''}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref
                  .read(verificationControllerProvider)
                  .approveVerification(provider['id'].toString());
              if (!context.mounted) return;
              Navigator.pop(ctx);
              if (ok) {
                ref.invalidate(userListProvider(
                    const UserListParams(rol: 'provider', pageSize: 100)));
                ref.invalidate(pendingVerificationsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Proveedor verificado'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> provider) {
    final nameController =
        TextEditingController(text: provider['name']?.toString() ?? '');
    final emailController =
        TextEditingController(text: provider['email']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Proveedor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Proveedor actualizado')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> provider) {
    final name =
        provider['name']?.toString() ?? provider['nombre']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error, size: 24),
            SizedBox(width: 12),
            Text('Eliminar Proveedor'),
          ],
        ),
        content: Text(
            '\u00bfEst\u00e1s seguro de eliminar a "$name"? Esta acci\u00f3n no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref
                  .read(userManagementControllerProvider)
                  .deleteUser(provider['id'].toString());
              if (!context.mounted) return;
              Navigator.pop(ctx);
              if (ok) {
                ref.invalidate(userListProvider(
                    const UserListParams(rol: 'provider', pageSize: 100)));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Proveedor eliminado'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al eliminar proveedor'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
