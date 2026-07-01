import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookings/presentation/providers/booking_provider.dart';
import '../../data/models/quote_model.dart';
import '../../data/repositories/quote_repository.dart';

class QuoteFormState {
  final bool isLoading;
  final String? error;
  final QuoteModel? quote;

  const QuoteFormState({this.isLoading = false, this.error, this.quote});

  QuoteFormState copyWith(
          {bool? isLoading, String? error, QuoteModel? quote}) =>
      QuoteFormState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        quote: quote ?? this.quote,
      );
}

class QuoteFormNotifier extends Notifier<QuoteFormState> {
  @override
  QuoteFormState build() => const QuoteFormState();

  Future<bool> create(String serviceId, String description) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final req = QuoteCreateRequest(serviceId: serviceId, description: description);
      final quote = await ref.read(quoteRepositoryProvider).createQuote(req);
      state = state.copyWith(isLoading: false, quote: quote);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> respond(String quoteId, String status, double? proposedPrice, {DateTime? startTime}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final req = QuoteRespondRequest(
        status: status,
        proposedPrice: proposedPrice,
        startTime: startTime,
      );
      await ref.read(quoteRepositoryProvider).respondToQuote(quoteId, req);
      state = state.copyWith(isLoading: false);
      ref.invalidate(myQuotesProvider);
      ref.invalidate(receivedQuotesProvider);
      ref.invalidate(myBookingsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() => state = const QuoteFormState();
}

final quoteFormControllerProvider =
    NotifierProvider<QuoteFormNotifier, QuoteFormState>(
        QuoteFormNotifier.new);

final myQuotesProvider = FutureProvider<List<QuoteModel>>((ref) {
  final authState = ref.watch(authControllerProvider);
  if (!authState.value!.isAuthenticated) return [];
  return ref.read(quoteRepositoryProvider).getMyQuotes();
});

final receivedQuotesProvider = FutureProvider<List<QuoteModel>>((ref) {
  final authState = ref.watch(authControllerProvider);
  if (!authState.value!.isAuthenticated) return [];
  return ref.read(quoteRepositoryProvider).getReceivedQuotes();
});
