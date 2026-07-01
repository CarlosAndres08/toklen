import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../favorites/presentation/screens/favorites_screen.dart';
import '../../../quotes/presentation/screens/quotes_list_screen.dart';
import '../../../schedules/presentation/screens/schedule_screen.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _addressController;

  XFile? _selectedImage;
  Uint8List? _webImage;

  @override
  void initState() {
    super.initState();
    final UserModel? user = ref.read(authControllerProvider).value?.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _webImage = bytes;
          _selectedImage = image;
        });
      } else {
        setState(() {
          _selectedImage = image;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);

    // 1. Si hay una imagen nueva, la subimos primero
    if (_selectedImage != null) {
      final List<int> bytes = await _selectedImage!.readAsBytes();
      final imageSuccess = await ref
          .read(profileControllerProvider.notifier)
          .uploadPicture(fileBytes: bytes, fileName: _selectedImage!.name);

      if (!imageSuccess) {
        // El error ya lo maneja el listener del provider mostrando un snackbar
        return;
      }
    }

    // 2. Guardamos los demás datos
    final bool success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfileData(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          bio: _bioController.text.trim(),
          address: _addressController.text.trim(),
        );

    if (success && mounted) {
      setState(() {
        _selectedImage = null;
        _webImage = null;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Perfil guardado correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? user = ref.watch(authControllerProvider).value?.user;
    final AsyncValue<void> profileState = ref.watch(profileControllerProvider);
    final bool isLoading = profileState.isLoading;

    ref.listen<AsyncValue<void>>(profileControllerProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString()), backgroundColor: AppColors.error),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth > 1200
              ? 800
              : constraints.maxWidth > 800
                  ? 600
                  : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  constraints.maxWidth > 600 ? 32.0 : 16.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: AppColors.primaryContainer,
                              backgroundImage: _selectedImage != null
                                  ? (kIsWeb
                                      ? MemoryImage(_webImage!)
                                      : FileImage(File(_selectedImage!.path)) as ImageProvider)
                                  : (user?.profilePictureUrl != null && user!.profilePictureUrl!.isNotEmpty
                                      ? NetworkImage(user.profilePictureUrl!)
                                      : null),
                              child: (_selectedImage == null && (user?.profilePictureUrl == null || user!.profilePictureUrl!.isEmpty))
                                  ? Text(
                                      user?.name?.isNotEmpty == true ? user!.name![0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 40, color: AppColors.primary, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            FloatingActionButton.small(
                              onPressed: isLoading ? null : _pickImage,
                              backgroundColor: AppColors.primary,
                              child: const Icon(Icons.camera_alt, color: AppColors.onPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: user?.role == 'provider' ? AppColors.primary.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user?.role == 'admin' 
                                ? '⚡ ADMINISTRADOR'
                                : user?.role == 'provider' 
                                    ? '💎 PROVEEDOR DE SERVICIOS' 
                                    : '👤 CLIENTE',
                            style: TextStyle(
                              color: user?.role == 'admin' 
                                  ? AppColors.error
                                  : user?.role == 'provider' 
                                      ? AppColors.primary 
                                      : AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      AppTextField(
                        controller: _nameController,
                        label: 'Nombre completo',
                        prefixIcon: Icons.person_outline,
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) return 'El nombre es obligatorio';
                          if (value.trim().length < 3) return 'Ingresa un nombre válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      AppTextField(
                        controller: _phoneController,
                        label: 'Teléfono',
                        prefixIcon: Icons.phone_outlined,
                        hintText: '+51 999 888 777',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _addressController,
                        label: 'Dirección',
                        prefixIcon: Icons.location_on_outlined,
                        hintText: 'Ciudad, Distrito, Calle...',
                        validator: (String? value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (value.trim().length < 5) return 'Ingresa una dirección más descriptiva';
                            // Evitar direcciones que solo sean números o caracteres basura
                            if (RegExp(r'^[0-9]+$').hasMatch(value.trim())) return 'Ingresa una dirección válida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _bioController,
                        label: 'Biografía / Sobre mí',
                        prefixIcon: Icons.info_outline,
                        hintText: 'Cuéntanos sobre tu experiencia profesional...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      PrimaryButton(
                        label: 'Guardar Cambios',
                        icon: Icons.save_outlined,
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _saveProfile,
                      ),

                      const SizedBox(height: 12),

                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  QuotesListScreen(isProvider: user?.role == 'provider'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.request_quote_outlined, color: AppColors.primary),
                        label: Text(
                          user?.role == 'provider' ? 'Cotizaciones Recibidas' : 'Mis Cotizaciones',
                          style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FavoritesScreen()),
                          );
                        },
                        icon: const Icon(Icons.favorite_outline, color: AppColors.error),
                        label: const Text(
                          'Mis Favoritos',
                          style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.error, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (user?.role == 'admin') ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminDashboardScreen()),
                            );
                          },
                          icon: const Icon(Icons.admin_panel_settings, color: AppColors.secondary),
                          label: const Text(
                            'Panel Admin',
                            style: TextStyle(color: AppColors.secondary, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.secondary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (user?.role == 'provider') ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ScheduleScreen()),
                            );
                          },
                          icon: const Icon(Icons.access_time, color: AppColors.primary),
                          label: const Text(
                            'Mis Horarios',
                            style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      const Divider(height: 1, color: Colors.black12),
                      const SizedBox(height: 16),

                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).logout();
                        },
                        icon: const Icon(Icons.logout, color: Colors.grey),
                        label: const Text(
                          'Cerrar Sesión', 
                          style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
