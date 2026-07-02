import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final Provider<TokenStorage> tokenStorageProvider = Provider<TokenStorage>(
  (Ref ref) => TokenStorage(),
);

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((Ref ref) {
      return AuthRepository(
        client: ref.watch(dioProvider),
        tokenStorage: ref.watch(tokenStorageProvider),
      );
    });

final AsyncNotifierProvider<AuthController, AuthState> authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthState {
  const AuthState({
    this.user,
    this.accessToken,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final UserModel? user;
  final String? accessToken;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isAuthenticated => (accessToken ?? '').isNotEmpty && user != null;

  AuthState copyWith({
    UserModel? user,
    String? accessToken,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      user: clearSession ? null : user ?? this.user,
      accessToken: clearSession ? null : accessToken ?? this.accessToken,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final AuthRepository repository = ref.watch(authRepositoryProvider);
    await Future<void>.delayed(const Duration(milliseconds: 850));

    final String? accessToken = await repository.readToken();

    if ((accessToken ?? '').isEmpty) {
      return const AuthState();
    }

    try {
      final UserModel user = await repository.getCurrentUser(accessToken!);
      return AuthState(user: user, accessToken: accessToken);
    } on Object {
      await repository.clearSession();
      return const AuthState();
    }
  }

  Future<void> login({required String email, required String password}) async {
    final AuthState currentState = state.value ?? const AuthState();
    state = AsyncData(
      currentState.copyWith(isSubmitting: true, clearError: true),
    );

    try {
      final AuthRepository repository = ref.read(authRepositoryProvider);
      final response = await repository.login(email: email, password: password);
      final String accessToken = response.accessToken ?? '';

      if (accessToken.isEmpty || response.user == null) {
        throw const ApiException('La respuesta de autenticacion no es valida.');
      }

      await repository.persistToken(accessToken);
      state = AsyncData(
        AuthState(user: response.user, accessToken: accessToken),
      );
    } on ApiException catch (error) {
      state = AsyncData(
        currentState.copyWith(isSubmitting: false, errorMessage: error.message),
      );
    } on Object {
      state = AsyncData(
        currentState.copyWith(
          isSubmitting: false,
          errorMessage: 'No pudimos iniciar sesion. Revisa tu conexion.',
        ),
      );
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String rol,
  }) async {
    final AuthState currentState = state.value ?? const AuthState();
    state = AsyncData(
      currentState.copyWith(isSubmitting: true, clearError: true),
    );

    try {
      final AuthRepository repository = ref.read(authRepositoryProvider);
      await repository.register(
        name: name,
        email: email,
        password: password,
        rol: rol,
      );

      state = AsyncData(
        currentState.copyWith(isSubmitting: false, clearError: true),
      );
      return true;
    } on ApiException catch (error) {
      state = AsyncData(
        currentState.copyWith(isSubmitting: false, errorMessage: error.message),
      );
      return false;
    } on Object {
      state = AsyncData(
        currentState.copyWith(
          isSubmitting: false,
          errorMessage: 'No pudimos crear la cuenta. Intentalo otra vez.',
        ),
      );
      return false;
    }
  }

  Future<void> logout() async {
    final AuthRepository repository = ref.read(authRepositoryProvider);
    await repository.clearSession();
    state = const AsyncData(AuthState());
  }

  void clearError() {
    final AuthState currentState = state.value ?? const AuthState();
    state = AsyncData(currentState.copyWith(clearError: true));
  }
}
