import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';

final Provider<ReviewRepository> reviewRepositoryProvider =
    Provider<ReviewRepository>((Ref ref) {
  return ReviewRepository(
    client: ref.watch(httpClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
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
      final token = ref.read(authControllerProvider).value?.accessToken ?? '';
      await ref
          .read(reviewRepositoryProvider)
          .createReview(token: token, request: request);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError('Error al crear reseña.', st);
      return false;
    }
  }
}
