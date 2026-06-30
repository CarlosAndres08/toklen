import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/admin_repository.dart';
import '../providers/category_management_provider.dart';
import '../widgets/category_card.dart';

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: categoriesAsync.when(
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
                          ref.invalidate(categoryListProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No hay categor\u00edas',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(categoryListProvider),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount =
                          constraints.maxWidth > 900
                              ? 4
                              : constraints.maxWidth > 600
                                  ? 3
                                  : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat =
                              categories[index] as Map<String, dynamic>;
                          return CategoryCard(
                            category: cat,
                            onEdit: () =>
                                _editCategoryDialog(context, cat),
                            onDelete: () =>
                                _confirmDeleteCategory(cat),
                          );
                        },
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
          const Icon(Icons.category, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Categor\u00edas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Gestiona las categor\u00edas del sistema',
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
            onPressed: () => ref.invalidate(categoryListProvider),
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _editCategoryDialog(context, null),
            tooltip: 'Nueva categor\u00eda',
          ),
        ],
      ),
    );
  }

  Future<String?> _pickAndUploadImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (file == null) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subiendo imagen...')),
      );

      final repository = ref.read(adminRepositoryProvider);
      final url = await repository.uploadFile(file.path);
      return url;
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al subir imagen: $e'),
              backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  void _editCategoryDialog(
      BuildContext context, Map<String, dynamic>? cat) {
    final nameController =
        TextEditingController(text: cat?['name']?.toString() ?? '');
    final descController =
        TextEditingController(text: cat?['description']?.toString() ?? '');
    final slugController =
        TextEditingController(text: cat?['slug']?.toString() ?? '');
    String? existingImage =
        cat?['image']?.toString() ?? cat?['imagen']?.toString();
    String? newImageUrl;
    bool isUploading = false;
    final isNew = cat == null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(isNew ? 'Nueva Categor\u00eda' : 'Editar Categor\u00eda'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: slugController,
                  decoration: const InputDecoration(
                    labelText: 'Slug',
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
                const SizedBox(height: 16),
                const Text('Imagen',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                if (existingImage != null && existingImage!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      existingImage!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: Colors.grey.shade200,
                        child: const Center(
                            child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (newImageUrl != null && newImageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      newImageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isUploading
                        ? null
                        : () async {
                            setDialogState(() => isUploading = true);
                            final url = await _pickAndUploadImage();
                            setDialogState(() {
                              isUploading = false;
                              if (url != null) {
                                newImageUrl = url;
                                existingImage = null;
                              }
                            });
                          },
                    icon: isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : const Icon(Icons.image, size: 18),
                    label: Text(isUploading
                        ? 'Subiendo...'
                        : 'Subir imagen'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                final data = <String, dynamic>{
                  'name': nameController.text.trim(),
                  'description': descController.text.trim(),
                };
                if (slugController.text.trim().isNotEmpty) {
                  data['slug'] = slugController.text.trim();
                }
                if (newImageUrl != null) {
                  data['image'] = newImageUrl;
                }

                bool ok;
                if (isNew) {
                  ok = await ref
                      .read(categoryManagementControllerProvider)
                      .createCategory(data);
                } else {
                  ok = await ref
                      .read(categoryManagementControllerProvider)
                      .updateCategory(cat['id'].toString(), data);

                  if (ok && newImageUrl != null) {
                    await ref
                        .read(categoryManagementControllerProvider)
                        .uploadCategoryImage(
                            cat['id'].toString(), newImageUrl!);
                  }
                }

                if (!context.mounted) return;
                Navigator.pop(ctx);
                if (ok) {
                  ref.invalidate(categoryListProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isNew
                          ? 'Categor\u00eda creada'
                          : 'Categor\u00eda actualizada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error al guardar categor\u00eda'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: Icon(isNew ? Icons.add : Icons.save, size: 18),
              label: Text(isNew ? 'Crear' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(Map<String, dynamic> cat) {
    final name = cat['name']?.toString() ?? cat['nombre']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error, size: 24),
            SizedBox(width: 12),
            Text('Eliminar Categor\u00eda'),
          ],
        ),
        content: Text(
            '\u00bfEst\u00e1s seguro de eliminar "$name"? Esta acci\u00f3n no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref
                  .read(categoryManagementControllerProvider)
                  .deleteCategory(cat['id'].toString());
              if (!context.mounted) return;
              Navigator.pop(ctx);
              if (ok) {
                ref.invalidate(categoryListProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Categor\u00eda eliminada'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al eliminar categor\u00eda'),
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
