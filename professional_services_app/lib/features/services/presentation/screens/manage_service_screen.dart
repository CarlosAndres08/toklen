import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/service_model.dart';
import '../providers/service_provider.dart';

class ManageServiceScreen extends ConsumerStatefulWidget {
  const ManageServiceScreen({required this.service, super.key});
  final ServiceModel service;
  @override
  ConsumerState<ManageServiceScreen> createState() => _ManageServiceScreenState();
}

class _ManageServiceScreenState extends ConsumerState<ManageServiceScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late bool _isActive;
  
  final int _maxImages = 5; 

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.service.title);
    _descriptionController = TextEditingController(text: widget.service.description);
    _priceController = TextEditingController(text: widget.service.price.toStringAsFixed(2));
    _isActive = widget.service.isActive;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    // CORRECCIÓN: Se envían los datos mediante ServiceUpdateRequest como requiere el provider
    final bool success = await ref.read(updateServiceControllerProvider.notifier).executeUpdate(
          serviceId: widget.service.id,
          request: ServiceUpdateRequest(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            price: double.tryParse(_priceController.text.trim()) ?? 0.0,
            isActive: _isActive,
          ),
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Actualizado con éxito'), backgroundColor: AppColors.success));
      Navigator.pop(context);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile == null) return;
      final List<int> bytes = await pickedFile.readAsBytes();
      final bool success = await ref.read(uploadServiceImageControllerProvider.notifier).executeUpload(
            serviceId: widget.service.id, imageBytes: bytes, fileName: pickedFile.name,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto subida exitosamente.'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de archivo.'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _deleteImage(String imageId) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar foto?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: AppColors.error))),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    final bool success = await ref.read(deleteServiceImageControllerProvider.notifier).executeDelete(
      serviceId: widget.service.id, imageId: imageId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto eliminada.'), backgroundColor: AppColors.success));
    } else if (mounted) {
      final errorState = ref.read(deleteServiceImageControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorState.error?.toString() ?? 'Error desconocido al eliminar.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceListState = ref.watch(serviceListProvider);
    final currentService = serviceListState.value?.firstWhere(
      (s) => s.id == widget.service.id,
      orElse: () => widget.service,
    ) ?? widget.service;

    final uploadState = ref.watch(uploadServiceImageControllerProvider);
    final updateState = ref.watch(updateServiceControllerProvider);
    final deleteState = ref.watch(deleteServiceImageControllerProvider);
    final bool isLoading = uploadState.isLoading || updateState.isLoading || deleteState.isLoading;

    final int currentImagesCount = currentService.images.length;
    final bool canUploadMore = currentImagesCount < _maxImages;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestionar Servicio', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        actions: [
          if (isLoading) const Padding(padding: EdgeInsets.all(16), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else TextButton(onPressed: _saveChanges, child: const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(controller: _titleController, label: 'Título', textInputAction: TextInputAction.next),
              const SizedBox(height: 16),
              AppTextField(controller: _priceController, label: 'Precio (S/)', keyboardType: TextInputType.number, textInputAction: TextInputAction.next),
              const SizedBox(height: 16),
              AppTextField(controller: _descriptionController, label: 'Descripción', maxLines: 3),
              const SizedBox(height: 16),
              SwitchListTile(title: const Text('Activo'), value: _isActive, activeThumbColor: AppColors.primary, onChanged: isLoading ? null : (val) => setState(() => _isActive = val)),
              const Divider(height: 48),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Galería', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('$currentImagesCount/$_maxImages fotos', style: TextStyle(color: canUploadMore ? AppColors.textSecondary : AppColors.error, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...currentService.images.map((img) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(img.url, width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 4, top: 4,
                        child: InkWell(
                          onTap: isLoading ? null : () => _deleteImage(img.id),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  )),
                  
                  if (canUploadMore)
                    InkWell(
                      onTap: isLoading ? null : _pickAndUploadImage,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(color: AppColors.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primary)),
                        child: const Icon(Icons.add_a_photo, color: AppColors.primary, size: 32),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}