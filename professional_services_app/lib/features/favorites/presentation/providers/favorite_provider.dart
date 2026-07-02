import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/favorite_repository.dart';

final favoriteIdsProvider = FutureProvider<List<String>>((ref) {
  final authState = ref.watch(authControllerProvider);
  if (!authState.value!.isAuthenticated) return [];
  return ref.read(favoriteRepositoryProvider).listFavoriteIds();
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (currentlyFavorited) {
        await ref.read(favoriteRepositoryProvider).removeFavorite(serviceId);
      } else {
        await ref.read(favoriteRepositoryProvider).addFavorite(serviceId);
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
