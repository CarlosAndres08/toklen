import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/user_management_provider.dart';
import '../../data/models/user_management_models.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _searchQuery = '';
  String? _rolFilter;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  UserListParams get _params => UserListParams(
        q: _searchQuery.isEmpty ? null : _searchQuery,
        rol: _rolFilter,
        pageSize: 100,
      );

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userListProvider(_params));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          const SizedBox(height: 8),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $e',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(userListProvider(_params)),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No se encontraron usuarios',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(userListProvider(_params)),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 700) {
                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user =
                                users[index] as Map<String, dynamic>;
                            return _buildUserCard(user);
                          },
                        );
                      }
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                              AppColors.surface),
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 72,
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('Avatar')),
                            DataColumn(label: Text('Nombre')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Rol')),
                            DataColumn(label: Text('Estado')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: users.map((u) {
                            final user =
                                u as Map<String, dynamic>;
                            return _buildUserRow(user);
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
          const Icon(Icons.people, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gesti\u00f3n de Usuarios',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Administra todos los usuarios del sistema',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _rolFilter,
                hint: const Text('Rol',
                    style: TextStyle(fontSize: 14)),
                items: const [
                  DropdownMenuItem(
                      value: null, child: Text('Todos los roles')),
                  DropdownMenuItem(
                      value: 'client', child: Text('Clientes')),
                  DropdownMenuItem(
                      value: 'provider', child: Text('Proveedores')),
                  DropdownMenuItem(
                      value: 'admin', child: Text('Administradores')),
                ],
                onChanged: (v) => setState(() => _rolFilter = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildUserRow(Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? user['nombre']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final role = user['role']?.toString() ?? user['rol']?.toString() ?? 'client';
    final isSuspended = user['is_suspended'] == true;
    final isActive = user['is_active'] != false;

    Color roleColor;
    String roleLabel;
    switch (role) {
      case 'admin':
        roleColor = Colors.red;
        roleLabel = 'Admin';
        break;
      case 'provider':
        roleColor = Colors.blue;
        roleLabel = 'Proveedor';
        break;
      default:
        roleColor = Colors.green;
        roleLabel = 'Cliente';
    }

    return DataRow(
      cells: [
        DataCell(
          CircleAvatar(
            radius: 18,
            backgroundColor: roleColor.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: roleColor),
            ),
          ),
        ),
        DataCell(Text(name,
            style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(email, style: const TextStyle(fontSize: 13))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(roleLabel,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: roleColor)),
        )),
        DataCell(
          isSuspended
              ? const Text('Suspendido',
                  style: TextStyle(color: Colors.orange, fontSize: 13))
              : isActive
                  ? const Text('Activo',
                      style: TextStyle(color: Colors.green, fontSize: 13))
                  : const Text('Inactivo',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSuspended)
              IconButton(
                onPressed: () => _unsuspendUser(user),
                icon: const Icon(Icons.unpublished,
                    color: Colors.orange, size: 20),
                tooltip: 'Reactivar',
                visualDensity: VisualDensity.compact,
              )
            else
              IconButton(
                onPressed: () => _confirmSuspend(user),
                icon: const Icon(Icons.block,
                    color: Colors.red, size: 20),
                tooltip: 'Suspender',
                visualDensity: VisualDensity.compact,
              ),
            IconButton(
              onPressed: () => _showEditDialog(user),
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.primary, size: 20),
              tooltip: 'Editar',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: () => _confirmDelete(user),
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

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? user['nombre']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final role =
        user['role']?.toString() ?? user['rol']?.toString() ?? 'client';
    final isSuspended = user['is_suspended'] == true;

    Color roleColor;
    String roleLabel;
    switch (role) {
      case 'admin':
        roleColor = Colors.red;
        roleLabel = 'ADMIN';
        break;
      case 'provider':
        roleColor = Colors.blue;
        roleLabel = 'PROVEEDOR';
        break;
      default:
        roleColor = Colors.green;
        roleLabel = 'CLIENTE';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: roleColor),
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
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(roleLabel,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: roleColor)),
                      ),
                      if (isSuspended) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('SUSPENDIDO',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (v) {
                if (v == 'edit') _showEditDialog(user);
                if (v == 'suspend' && !isSuspended) _confirmSuspend(user);
                if (v == 'unsuspend' && isSuspended) _unsuspendUser(user);
                if (v == 'delete') _confirmDelete(user);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                if (isSuspended)
                  const PopupMenuItem(
                      value: 'unsuspend', child: Text('Reactivar'))
                else
                  const PopupMenuItem(
                      value: 'suspend', child: Text('Suspender')),
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

  void _showEditDialog(Map<String, dynamic> user) {
    final nameController =
        TextEditingController(text: user['name']?.toString() ?? '');
    final apellidoController =
        TextEditingController(text: user['apellido']?.toString() ?? '');
    final emailController =
        TextEditingController(text: user['email']?.toString() ?? '');
    final phoneController =
        TextEditingController(text: user['phone']?.toString() ?? '');
    String selectedRole =
        user['role']?.toString() ?? user['rol']?.toString() ?? 'client';
    bool isActive = user['is_active'] != false;
    bool isVerified = user['is_verified'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Editar Usuario'),
          content: SingleChildScrollView(
            child: Column(
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
                  controller: apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
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
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Tel\u00e9fono',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'client', child: Text('Cliente')),
                    DropdownMenuItem(
                        value: 'provider', child: Text('Proveedor')),
                    DropdownMenuItem(
                        value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedRole = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Activo'),
                  value: isActive,
                  onChanged: (v) =>
                      setDialogState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Verificado'),
                  value: isVerified,
                  onChanged: (v) =>
                      setDialogState(() => isVerified = v),
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
                final request = UserUpdateRequest(
                  name: nameController.text.trim(),
                  apellido: apellidoController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  rol: selectedRole,
                  isActive: isActive,
                  isVerified: isVerified,
                );
                final ok = await ref
                    .read(userManagementControllerProvider)
                    .updateUser(user['id'].toString(), request);
                if (!context.mounted) return;
                Navigator.pop(ctx);
                if (ok) {
                  ref.invalidate(userListProvider(_params));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Usuario actualizado'),
                        backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Error al actualizar usuario'),
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

  void _confirmSuspend(Map<String, dynamic> user) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Suspender Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '\u00bfSuspender a ${user['name'] ?? user['nombre'] ?? ''}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo de suspensi\u00f3n *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              final ok = await ref
                  .read(userManagementControllerProvider)
                  .suspendUser(user['id'].toString(),
                      reasonController.text.trim());
              if (!context.mounted) return;
              Navigator.pop(context);
              if (ok) {
                ref.invalidate(userListProvider(_params));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario suspendido'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al suspender usuario'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.block, size: 18),
            label: const Text('Suspender'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _unsuspendUser(Map<String, dynamic> user) async {
    final ok = await ref
        .read(userManagementControllerProvider)
        .unsuspendUser(user['id'].toString());
    if (!context.mounted) return;
    if (ok) {
      ref.invalidate(userListProvider(_params));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario reactivado'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error, size: 24),
            SizedBox(width: 12),
            Text('Eliminar Usuario'),
          ],
        ),
        content: Text(
            '\u00bfEst\u00e1s seguro de eliminar a "${user['name'] ?? user['nombre'] ?? ''}"? Esta acci\u00f3n no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref
                  .read(userManagementControllerProvider)
                  .deleteUser(user['id'].toString());
              if (!context.mounted) return;
              Navigator.pop(ctx);
              if (ok) {
                ref.invalidate(userListProvider(_params));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario eliminado'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al eliminar usuario'),
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
