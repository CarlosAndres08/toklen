import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/schedule_model.dart';
import '../../data/repositories/schedule_repository.dart';

final myScheduleProvider = FutureProvider<List<ScheduleModel>>((ref) {
  final userId = ref.read(authControllerProvider).value?.user?.id;
  if (userId == null || userId.isEmpty) return [];
  return ref.read(scheduleRepositoryProvider).getProviderSchedule(userId);
});

class ScheduleFormState {
  final bool isLoading;
  final String? error;
  final ScheduleModel? schedule;

  const ScheduleFormState({this.isLoading = false, this.error, this.schedule});

  ScheduleFormState copyWith(
          {bool? isLoading, String? error, ScheduleModel? schedule}) =>
      ScheduleFormState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        schedule: schedule ?? this.schedule,
      );
}

class ScheduleFormNotifier extends Notifier<ScheduleFormState> {
  @override
  ScheduleFormState build() => const ScheduleFormState();

  Future<bool> create(ScheduleCreateRequest req) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final schedule = await ref.read(scheduleRepositoryProvider).createSchedule(req);
      state = state.copyWith(isLoading: false, schedule: schedule);
      ref.invalidate(myScheduleProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> delete(String scheduleId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(scheduleRepositoryProvider).deleteSchedule(scheduleId);
      state = state.copyWith(isLoading: false);
      ref.invalidate(myScheduleProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final scheduleFormControllerProvider =
    NotifierProvider<ScheduleFormNotifier, ScheduleFormState>(
        ScheduleFormNotifier.new);
