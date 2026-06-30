import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/service_management_provider.dart';
import '../providers/category_management_provider.dart';

class AdminServicesScreen extends ConsumerStatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  ConsumerState<AdminServicesScreen> createState() =>
      _AdminServicesScreenState();
}

class _AdminServicesScreenState extends ConsumerState<AdminServicesScreen> {
  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(serviceListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: servicesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(serviceListProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (services) {
                if (services.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build_circle_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No hay servicios disponibles',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(serviceListProvider),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 700) {
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final service =
                                services[index] as Map<String, dynamic>;
                            return _buildServiceCard(service);
                          },
                        );
                      }
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(AppColors.surface),
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 72,
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('T\u00edtulo')),
                            DataColumn(label: Text('Proveedor')),
                            DataColumn(label: Text('Categor\u00eda')),
                            DataColumn(label: Text('Precio')),
                            DataColumn(label: Text('Activo')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: services.map((s) {
                            final service =
                                s as Map<String, dynamic>;
                            return _buildServiceRow(service);
                          }).toList(),
                        ),
                      );
                    },
                  ),
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          const Icon(Icons.build, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Servicios',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Administra los servicios del sistema',
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
            onPressed: () => ref.invalidate(serviceListProvider),
            tooltip: 'Actualizar',
          ),
        ],
      ),
    );
  }

  DataRow _buildServiceRow(Map<String, dynamic> service) {
    final title =
        service['title']?.toString() ?? service['titulo']?.toString() ?? '';
    final providerName = service['provider_name']?.toString() ??
        service['proveedor']?.toString() ??
        '';
    final categoryName = service['category_name']?.toString() ??
        service['categoria']?.toString() ??
        '';
    final price = service['price']?.toString() ?? '0';
    final isActive = service['is_active'] != false;
    final isApproved = service['is_approved'] == true;

    return DataRow(
      cells: [
        DataCell(Text(title,
            style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(providerName,
            style: const TextStyle(fontSize: 13))),
        DataCell(Text(categoryName,
            style: const TextStyle(fontSize: 13))),
        DataCell(Text('\$$price',
            style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(
          isActive
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
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('No',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
        ),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isApproved)
              IconButton(
                onPressed: () => _approveService(service),
                icon: const Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 20),
                tooltip: 'Aprobar',
                visualDensity: VisualDensity.compact,
              ),
            if (!isApproved)
              IconButton(
                onPressed: () => _rejectService(service),
                icon: const Icon(Icons.cancel_outlined,
                    color: Colors.red, size: 20),
                tooltip: 'Rechazar',
                visualDensity: VisualDensity.compact,
              ),
            IconButton(
              onPressed: () => _editServiceDialog(service),
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.primary, size: 20),
              tooltip: 'Editar',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: () => _confirmDelete(service),
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

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final title =
        service['title']?.toString() ?? service['titulo']?.toString() ?? '';
    final providerName = service['provider_name']?.toString() ??
        service['proveedor']?.toString() ??
        '';
    final isApproved = service['is_approved'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.build, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  Text(providerName,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isApproved
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isApproved ? 'APROBADO' : 'PENDIENTE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isApproved ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (v) {
                if (v == 'approve' && !isApproved) {
                  _approveService(service);
                }
                if (v == 'reject' && !isApproved) {
                  _rejectService(service);
                }
                if (v == 'edit') _editServiceDialog(service);
                if (v == 'delete') _confirmDelete(service);
              },
              itemBuilder: (_) => [
                if (!isApproved)
                  const PopupMenuItem(
                      value: 'approve', child: Text('Aprobar')),
                if (!isApproved)
                  const PopupMenuItem(
                      value: 'reject', child: Text('Rechazar')),
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

  void _editServiceDialog(Map<String, dynamic> service) {
    final titleController =
        TextEditingController(text: service['title']?.toString() ?? '');
    final descController =
        TextEditingController(text: service['description']?.toString() ?? '');
    final priceController =
        TextEditingController(text: service['price']?.toString() ?? '');
    String? selectedCategory;
    var isActive = service['is_active'] != false;
    final categoriesAsync = ref.read(categoryListProvider);

    categoriesAsync.whenData((categories) {
      final currentCat = service['category_id']?.toString() ??
          service['categoria_id']?.toString();
      if (categories.any(
          (c) => c['id'].toString() == currentCat)) {
        selectedCategory = currentCat;
      }
    });

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar Servicio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'T\u00edtulo',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Descripci\u00f3n',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categor\u00eda',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: categories.map((c) {
                      final cat = c as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: cat['id'].toString(),
                        child: Text(cat['name']?.toString() ?? ''),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(
                            () => selectedCategory = v);
                      }
                    },
                  ),
                  loading: () => const SizedBox(
                      height: 40,
                      child: Center(
                          child:
                              CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, __) => const Text('Error al cargar categor\u00edas'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Activo'),
                  value: isActive,
                  onChanged: (v) =>
                      setDialogState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = <String, dynamic>{
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'price': double.tryParse(priceController.text.trim()) ?? 0,
                  'is_active': isActive,
                };
                if (selectedCategory != null) {
                  data['category_id'] = selectedCategory;
                }
                final ok = await ref
                    .read(serviceManagementControllerProvider)
                    .updateService(
                        service['id'].toString(), data);
                if (!context.mounted) return;
                Navigator.pop(ctx);
                if (ok) {
                  ref.invalidate(serviceListProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Servicio actualizado'),
                        backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Error al actualizar servicio'),
                        backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _approveService(Map<String, dynamic> service) {
    final title =
        service['title']?.toString() ?? service['titulo']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Aprobar Servicio'),
        content: Text('\u00bfAprobar "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref
                  .read(serviceManagementControllerProvider)
                  .approveService(service['id'].toString());
              if (!context.mounted) return;
              Navigator.pop(ctx);
              if (ok) {
                ref.invalidate(serviceListProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Servicio aprobado'),
                      backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Error al aprobar servicio'),
                      backgroundColor: Colors.red),
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

  void _rejectService(Map<String, dynamic> service) {
    final reasonController = TextEditingController();
    final title =
        service['title']?.toString() ?? service['titulo']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rechazar Servicio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rechazar "$title"'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              final ok = await ref
                  .read(serviceManagementControllerProvider)
                  .rejectService(service['id'].toString(),
                      reasonController.text.trim());
              if (!context.mounted) return;
              Navigator.pop(ctx);
              if (ok) {
                ref.invalidate(serviceListProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Servicio rechazado'),
                      backgroundColor: Colors.orange),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Error al rechazar servicio'),
                      backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> service) {
    final title =
        service['title']?.toString() ?? service['titulo']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error, size: 24),
            SizedBox(width: 12),
            Text('Eliminar Servicio'),
          ],
        ),
        content: Text(
            '\u00bfEst\u00e1s seguro de eliminar "$title"? Esta acci\u00f3n no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref
                  .read(serviceManagementControllerProvider)
                  .deleteService(service['id'].toString());
              if (!context.mounted) return;
              Navigator.pop(ctx);
              if (ok) {
                ref.invalidate(serviceListProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Servicio eliminado'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al eliminar servicio'),
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
