import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/profile_repository.dart';

// Inyección de dependencias
final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>((Ref ref) {
  return ProfileRepository(
    client: ref.watch(dioProvider),
  );
});

// El Notifier principal
final AsyncNotifierProvider<ProfileController, void> profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

class ProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Estado inicial, no hacemos nada al arrancar
    return;
  }

  /// Método para actualizar datos de texto
  Future<bool> updateProfileData({
    String? name,
    String? phone,
    String? bio,
    String? address,
  }) async {
    state = const AsyncLoading<void>();
    try {
      final ProfileRepository repository = ref.read(profileRepositoryProvider);
      
      final UserModel updatedUser = await repository.updateProfile(
        name: name,
        phone: phone,
        bio: bio,
        address: address,
      );

      _updateGlobalSession(updatedUser);
      state = const AsyncData<void>(null);
      return true;
    } on ApiException catch (e, st) {
      state = AsyncError<void>(e.message, st);
      return false;
    } on Object catch (e, st) {
      state = AsyncError<void>('No se pudo guardar la informacion.', st);
      return false;
    }
  }

  /// Método para subir la foto en Web
  Future<bool> uploadPicture({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    state = const AsyncLoading<void>();
    try {
      final ProfileRepository repository = ref.read(profileRepositoryProvider);
      
      final UserModel updatedUser = await repository.uploadProfilePicture(
        fileBytes: fileBytes,
        fileName: fileName,
      );

      _updateGlobalSession(updatedUser);
      state = const AsyncData<void>(null);
      return true;
    } on ApiException catch (e, st) {
      state = AsyncError<void>(e.message, st);
      return false;
    } on Object catch (e, st) {
      state = AsyncError<void>('Error al subir la imagen.', st);
      return false;
    }
  }

  /// Magia de Riverpod: Inyectamos el nuevo usuario en el AuthController global
  void _updateGlobalSession(UserModel newUser) {
    // En un proyecto Riverpod avanzado, en lugar de mutar el state desde fuera, 
    // lo ideal es invalidar el provider de Auth para que vuelva a pedir los datos a la API,
    // o hacer que el AuthController escuche este provider. 
    // Por simplicidad y rendimiento, forzaremos la actualización del AuthController recargándolo.
    ref.invalidate(authControllerProvider);
  }
}