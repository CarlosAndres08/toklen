import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../data/models/service_model.dart';
import '../providers/service_provider.dart';

class AddServiceScreen extends ConsumerStatefulWidget {
  const AddServiceScreen({super.key});

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  String? _selectedCategoryId;
  final List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una categoría.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final createdService = await ref
    .read(createServiceControllerProvider.notifier)
    .executeCreate(
      ServiceCreateRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        categoryId: _selectedCategoryId!,
      ),
    );
    
    if (createdService != null && mounted) {
      if (_selectedImages.isNotEmpty) {
        for (var image in _selectedImages) {
          final bytes = await image.readAsBytes();
          await ref.read(uploadServiceImageControllerProvider.notifier).executeUpload(
            serviceId: createdService.id,
            imageBytes: bytes,
            fileName: image.name,
          );
        }
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('¡Servicio publicado con éxito!'), backgroundColor: AppColors.success),
      );
      navigator.pop();
    } else if (mounted) {
      final errorState = ref.read(createServiceControllerProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(errorState.error?.toString() ?? 'Error al crear el servicio.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> createStatus = ref.watch(createServiceControllerProvider);
    final uploadStatus = ref.watch(uploadServiceImageControllerProvider);
    final bool isLoading = createStatus.isLoading || uploadStatus.isLoading;
    final categoriesAsync = ref.watch(categoryListProvider);

    final authState = ref.watch(authControllerProvider).value;
    final isVerified = authState?.user?.isVerified ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Publicar Servicio', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isVerified) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tu cuenta aún no está verificada. Puedes publicar servicios, pero aparecerán con menor prioridad hasta que un administrador valide tu perfil.',
                          style: TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                'Detalles de tu servicio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Título del servicio',
                  hintText: 'Ej. Reparación de computadoras a domicilio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => value == null || value.trim().length < 5 
                    ? 'Ingresa un título válido (mínimo 5 letras)' 
                    : null,
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Error al cargar categorías: $err', style: const TextStyle(color: AppColors.error)),
                data: (categories) {
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name ?? 'Sin nombre'),
                      );
                    }).toList(),
                    onChanged: isLoading ? null : (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                enabled: !isLoading,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio base (S/)',
                  hintText: 'Ej. 50.00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa un precio';
                  if (double.tryParse(value) == null) return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !isLoading,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descripción detallada',
                  hintText: 'Explica qué incluye tu servicio, tus años de experiencia, etc.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().length < 10 
                    ? 'Sé un poco más específico (mínimo 10 letras)' 
                    : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Fotos del servicio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    InkWell(
                      onTap: isLoading ? null : _pickImages,
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.add_a_photo, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ..._selectedImages.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(entry.value.path), width: 100, height: 100, fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: InkWell(
                                onTap: () => _removeImage(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: isLoading ? 'Publicando...' : 'Publicar Servicio',
                onPressed: isLoading ? null : _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
