import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
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

final AsyncNotifierProvider<CreateReviewController, void>
    createReviewControllerProvider =
    AsyncNotifierProvider<CreateReviewController, void>(
  CreateReviewController.new,
);

class CreateReviewController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> executeCreate(ReviewCreateRequest request) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(reviewRepositoryProvider)
          .createReview(request: request);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError('Error al crear reseña.', st);
      return false;
    }
  }
}
