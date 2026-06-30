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

  @override
  void initState() {
    super.initState();
    // Cargamos los datos actuales del usuario en los campos de texto
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

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final List<int> bytes = await image.readAsBytes();
      
      if (!mounted) return;
      final bool success = await ref
          .read(profileControllerProvider.notifier)
          .uploadPicture(fileBytes: bytes, fileName: image.name);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada exitosamente')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final bool success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfileData(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          bio: _bioController.text.trim(),
          address: _addressController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos al usuario actual para actualizar la UI si cambia la foto
    final UserModel? user = ref.watch(authControllerProvider).value?.user;
    // Escuchamos el estado del perfil para saber si está cargando
    final AsyncValue<void> profileState = ref.watch(profileControllerProvider);
    final bool isLoading = profileState.isLoading;

    // Escuchamos errores del provider de perfil
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
          // 🔥 RESPONSIVIDAD: Ajustar ancho máximo según el tamaño de pantalla
          final double maxWidth = constraints.maxWidth > 1200
              ? 800  // Desktop grande
              : constraints.maxWidth > 800
                  ? 600  // Tablet
                  : double.infinity;  // Móvil

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  // 🔥 RESPONSIVIDAD: Padding adaptativo
                  constraints.maxWidth > 600 ? 32.0 : 16.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- SECCIÓN FOTO DE PERFIL ---
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: AppColors.primaryContainer,
                              backgroundImage: user?.profilePictureUrl != null && user!.profilePictureUrl!.isNotEmpty
                                  ? NetworkImage(user.profilePictureUrl!)
                                  : null,
                              child: user?.profilePictureUrl == null || user!.profilePictureUrl!.isEmpty
                                  ? Text(
                                      user?.name?.isNotEmpty == true ? user!.name![0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 40, color: AppColors.primary, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            FloatingActionButton.small(
                              onPressed: isLoading ? null : _pickAndUploadImage,
                              backgroundColor: AppColors.primary,
                              child: isLoading 
                                ? const CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2)
                                : const Icon(Icons.camera_alt, color: AppColors.onPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🔥 ETIQUETA (BADGE) DEL ROL DEL USUARIO
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

                      // --- SECCIÓN FORMULARIO ---
                      AppTextField(
                        controller: _nameController,
                        label: 'Nombre completo',
                        prefixIcon: Icons.person_outline,
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) return 'El nombre es obligatorio';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      AppTextField(
                        controller: _phoneController,
                        label: 'Teléfono',
                        prefixIcon: Icons.phone_outlined,
                        hintText: '+51 999 888 777',
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _addressController,
                        label: 'Dirección',
                        prefixIcon: Icons.location_on_outlined,
                        hintText: 'Ciudad, Distrito',
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _bioController,
                        label: 'Biografía / Sobre mí',
                        prefixIcon: Icons.info_outline,
                        hintText: 'Cuéntanos sobre tu experiencia profesional...',
                      ),
                      const SizedBox(height: 32),

                      // --- BOTÓN GUARDAR ---
                      PrimaryButton(
                        label: 'Guardar Cambios',
                        icon: Icons.save_outlined,
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _saveProfile,
                      ),

                      // 📏 ESPACIADO OPTIMIZADO Y LÍNEA FINA CONTIGUA
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

                      // 🔥 BOTÓN CERRAR SESIÓN
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