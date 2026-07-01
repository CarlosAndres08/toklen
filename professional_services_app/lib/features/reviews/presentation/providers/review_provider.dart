import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../services/presentation/providers/service_provider.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';

final Provider<ReviewRepository> reviewRepositoryProvider =
    Provider<ReviewRepository>((Ref ref) {
  return ReviewRepository(
    client: ref.watch(dioProvider),
  );
});

final serviceReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>(
  (ref, serviceId) {
    return ref.read(reviewRepositoryProvider).getServiceReviews(serviceId);
  },
);

final AsyncNotifierProvider<ReviewController, void>
    reviewControllerProvider =
    AsyncNotifierProvider<ReviewController, void>(
  ReviewController.new,
);

class ReviewController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> executeCreate({
    required ReviewCreateRequest request,
    required String serviceId,
    required String providerId,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(reviewRepositoryProvider)
          .createReview(request: request);
      state = const AsyncData(null);
      _invalidateRelevantData(serviceId, providerId);
      return true;
    } catch (e, st) {
      state = AsyncError('Error al crear reseña.', st);
      return false;
    }
  }

  Future<bool> executeUpdate({
    required String reviewId,
    required int rating,
    String? comment,
    required String serviceId,
    required String providerId,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(reviewRepositoryProvider).updateReview(
            reviewId: reviewId,
            rating: rating,
            comment: comment,
          );
      state = const AsyncData(null);
      _invalidateRelevantData(serviceId, providerId);
      return true;
    } catch (e, st) {
      state = AsyncError('Error al actualizar reseña.', st);
      return false;
    }
  }

  Future<bool> executeDelete({
    required String reviewId,
    required String serviceId,
    required String providerId,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(reviewRepositoryProvider).deleteReview(reviewId);
      state = const AsyncData(null);
      _invalidateRelevantData(serviceId, providerId);
      return true;
    } catch (e, st) {
      state = AsyncError('Error al eliminar reseña.', st);
      return false;
    }
  }

  void _invalidateRelevantData(String serviceId, String providerId) {
    ref.invalidate(serviceReviewsProvider(serviceId));
    ref.invalidate(serviceListProvider);
    ref.invalidate(featuredServicesProvider);
    ref.invalidate(providerProfileProvider(providerId));
  }
}
