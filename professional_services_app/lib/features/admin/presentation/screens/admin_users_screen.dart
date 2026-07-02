import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeleton_loader.dart';
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
          const SizedBox(height: 16),
          Expanded(
            child: usersAsync.when(
              loading: () => _buildSkeleton(),
              error: (e, _) => EmptyState(
                title: 'Error de carga',
                message: e.toString(),
                icon: Icons.error_outline,
                actionLabel: 'Reintentar',
                onActionPressed: () => ref.invalidate(userListProvider(_params)),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return const EmptyState(
                    title: 'No se encontraron usuarios',
                    message: 'Intenta con otros términos de búsqueda o filtros.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(userListProvider(_params)),
                  child: _buildContent(users),
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
          const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 32),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestión de Usuarios',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
              ),
              Text(
                'Administra accesos, roles y sanciones',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _rolFilter,
                hint: const Text('Filtrar por Rol', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'client', child: Text('Clientes')),
                  DropdownMenuItem(value: 'provider', child: Text('Proveedores')),
                  DropdownMenuItem(value: 'admin', child: Text('Admins')),
                ],
                onChanged: (v) => setState(() => _rolFilter = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<dynamic> users) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 800) {
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: users.length,
          itemBuilder: (context, index) => _buildUserMobileCard(users[index]),
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
            columns: const [
              DataColumn(label: Text('Usuario', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Rol', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.w700))),
            ],
            rows: users.map((u) => _buildUserRow(u as Map<String, dynamic>)).toList(),
          ),
        ),
      );
    });
  }

  DataRow _buildUserRow(Map<String, dynamic> user) {
    final name = user['nombre']?.toString() ?? user['name']?.toString() ?? 'U';
    final role = (user['rol'] ?? user['role'])?.toString() ?? 'client';
    final isSuspended = user['is_suspended'] == true;

    return DataRow(
      cells: [
        DataCell(Row(
          children: [
            CircleAvatar(radius: 16, child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U')),
            const SizedBox(width: 12),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        )),
        DataCell(Text(user['email']?.toString() ?? '-')),
        DataCell(_buildRoleBadge(role)),
        DataCell(_buildStatusBadge(isSuspended, user['is_active'] != false)),
        DataCell(Row(
          children: [
            IconButton(
              onPressed: () => _showEditDialog(user),
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
            ),
            if (isSuspended)
              IconButton(
                onPressed: () => _unsuspendUser(user),
                icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                tooltip: 'Reactivar',
              )
            else
              IconButton(
                onPressed: () => _showSuspendDialog(user),
                icon: const Icon(Icons.block_flipped, color: Colors.orange, size: 20),
                tooltip: 'Suspender',
              ),
            IconButton(
              onPressed: () => _confirmDelete(user),
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color = Colors.blue;
    if (role == 'admin') color = Colors.red;
    if (role == 'provider') color = AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(role.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildStatusBadge(bool isSuspended, bool isActive) {
    if (isSuspended) {
      return const Text('SUSPENDIDO', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11));
    }
    return Text(isActive ? 'ACTIVO' : 'INACTIVO',
      style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 11));
  }

  Widget _buildUserMobileCard(Map<String, dynamic> user) {
    final name = user['nombre']?.toString() ?? user['name']?.toString() ?? 'Usuario';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U')),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user['email']?.toString() ?? ''),
        trailing: _buildRoleBadge((user['rol'] ?? user['role'] ?? 'client').toString()),
        onTap: () => _showEditDialog(user),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['nombre']?.toString() ?? user['name']?.toString() ?? '');
    String selectedRole = (user['rol'] ?? user['role'] ?? 'client').toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: const [
                DropdownMenuItem(value: 'client', child: Text('Cliente')),
                DropdownMenuItem(value: 'provider', child: Text('Proveedor')),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
              ],
              onChanged: (v) {
                if (v != null) selectedRole = v;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);

              final ok = await ref.read(userManagementControllerProvider).updateUser(user['id'].toString(), UserUpdateRequest(nombre: nameController.text, rol: selectedRole));

              navigator.pop();
              if (ok) {
                ref.invalidate(userListProvider(_params));
              } else {
                messenger.showSnackBar(const SnackBar(content: Text('Error al actualizar usuario'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(Map<String, dynamic> user) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspender Usuario'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Motivo de suspensión'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              final navigator = Navigator.of(ctx);

              final ok = await ref.read(userManagementControllerProvider).suspendUser(user['id'].toString(), reasonController.text);

              navigator.pop();
              if (ok) {
                ref.invalidate(userListProvider(_params));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Suspender'),
          ),
        ],
      ),
    );
  }

  void _unsuspendUser(Map<String, dynamic> user) async {
    final ok = await ref.read(userManagementControllerProvider).unsuspendUser(user['id'].toString());
    if (ok) ref.invalidate(userListProvider(_params));
  }

  void _confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: const Text('¿Estás seguro de eliminar este usuario? Esta acción es irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);

              final ok = await ref.read(userManagementControllerProvider).deleteUser(user['id'].toString());

              navigator.pop();
              if (ok) {
                ref.invalidate(userListProvider(_params));
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
      child: Column(children: List.generate(5, (index) => const Padding(padding: EdgeInsets.only(bottom: 12), child: SkeletonLoader(width: double.infinity, height: 60, borderRadius: 12)))),
    );
  }
}
