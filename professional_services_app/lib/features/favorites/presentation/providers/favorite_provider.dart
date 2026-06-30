import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/favorite_repository.dart';

final favoriteIdsProvider = FutureProvider<List<String>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final token = authState.value?.accessToken ?? '';
  if (token.isEmpty) return [];
  return ref.read(favoriteRepositoryProvider).listFavoriteIds(token);
});

class FavoriteToggleState {
  final bool isLoading;
  final String? error;

  const FavoriteToggleState({this.isLoading = false, this.error});

  FavoriteToggleState copyWith({bool? isLoading, String? error}) =>
      FavoriteToggleState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class FavoriteToggleNotifier extends Notifier<FavoriteToggleState> {
  @override
  FavoriteToggleState build() => const FavoriteToggleState();

  Future<bool> toggle(String serviceId, bool currentlyFavorited) async {
    final token = ref.read(authControllerProvider).value?.accessToken ?? '';
    if (token.isEmpty) {
      state = state.copyWith(error: 'No hay sesión activa.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (currentlyFavorited) {
        await ref.read(favoriteRepositoryProvider).removeFavorite(token, serviceId);
      } else {
        await ref.read(favoriteRepositoryProvider).addFavorite(token, serviceId);
      }
      ref.invalidate(favoriteIdsProvider);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final favoriteToggleControllerProvider =
    NotifierProvider<FavoriteToggleNotifier, FavoriteToggleState>(FavoriteToggleNotifier.new);
