import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/schedule_model.dart';
import '../providers/schedule_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(myScheduleProvider);
    final formState = ref.watch(scheduleFormControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Horarios'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Horario actual',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            scheduleAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
              data: (schedules) {
                if (schedules.isEmpty) {
                  return Text(
                    'No has configurado horarios aún.',
                    style: TextStyle(color: Colors.grey.shade600),
                  );
                }
                return Column(
                  children: schedules
                      .map((s) => ListTile(
                            leading: Icon(Icons.access_time,
                                color: s.isActive
                                    ? AppColors.success
                                    : Colors.grey),
                            title: Text(s.dayName),
                            subtitle:
                                Text('${s.startTime} - ${s.endTime}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final ok = await ref
                                    .read(scheduleFormControllerProvider
                                        .notifier)
                                    .delete(s.id);
                                if (ok) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                        content: Text('Horario eliminado')),
                                  );
                                }
                              },
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const Divider(height: 40),
            const Text('Agregar horario',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _selectedDay,
              decoration: const InputDecoration(
                labelText: 'Día de la semana',
                border: OutlineInputBorder(),
              ),
              items: List.generate(7, (i) {
                return DropdownMenuItem(
                  value: i,
                  child: Text(dayNames[i]),
                );
              }),
              onChanged: (v) => setState(() => _selectedDay = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimePickerTile(
                    label: 'Inicio',
                    time: _startTime,
                    onPicked: (t) => setState(() => _startTime = t),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePickerTile(
                    label: 'Fin',
                    time: _endTime,
                    onPicked: (t) => setState(() => _endTime = t),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Guardar Horario',
              isLoading: formState.isLoading,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                if (_selectedDay == null ||
                    _startTime == null ||
                    _endTime == null) {
                  messenger.showSnackBar(
                    const SnackBar(
                        content:
                            Text('Completa todos los campos')),
                  );
                  return;
                }
                final req = ScheduleCreateRequest(
                  dayOfWeek: _selectedDay!,
                  startTime:
                      '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
                  endTime:
                      '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
                );
                final ok = await ref
                    .read(scheduleFormControllerProvider.notifier)
                    .create(req);
                if (ok) {
                  if (!mounted) return;
                  setState(() {
                    _selectedDay = null;
                    _startTime = null;
                    _endTime = null;
                  });
                  messenger.showSnackBar(
                    const SnackBar(
                        content:
                            Text('Horario guardado'),
                        backgroundColor: AppColors.success),
                  );
                } else {
                  if (!mounted) return;
                  if (formState.error != null) {
                    messenger.showSnackBar(
                      SnackBar(
                          content: Text(formState.error!)),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onPicked;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? const TimeOfDay(hour: 9, minute: 0),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          time != null
              ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
              : 'Seleccionar',
        ),
      ),
    );
  }
}
