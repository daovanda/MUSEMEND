import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/features/checkin/application/reflect_providers.dart';
import 'package:musemend/features/checkin/application/reflect_state.dart';
import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/missions/presentation/missions_section.dart';

class ReflectScreen extends ConsumerStatefulWidget {
  const ReflectScreen({super.key});

  @override
  ConsumerState<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends ConsumerState<ReflectScreen> {
  final _noteController = TextEditingController();
  Mood? _selectedMood;
  double? _energyLevel;
  String? _hydratedCheckinId;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _hydrate(ReflectState data) {
    final checkin = data.today;
    if (checkin == null || checkin.id == _hydratedCheckinId) return;
    _hydratedCheckinId = checkin.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedMood = checkin.mood;
        _energyLevel = checkin.energyLevel?.toDouble();
        _noteController.text = checkin.note ?? '';
      });
    });
  }

  Future<void> _save() async {
    final mood = _selectedMood;
    if (mood == null) return;
    final succeeded = await ref
        .read(reflectControllerProvider.notifier)
        .save(
          mood: mood,
          energyLevel: _energyLevel?.round(),
          note: _noteController.text,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? 'Đã lưu check-in hôm nay.'
              : 'Chưa thể lưu. Vui lòng thử lại.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reflectControllerProvider);
    state.whenData(_hydrate);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [MuseColors.sky, MuseColors.cream, MuseColors.mint],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (_, _) => _ErrorView(
                onRetry: () => ref.invalidate(reflectControllerProvider),
              ),
          data: (data) {
            final selected = _selectedMood ?? data.today?.mood;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hôm nay bạn thế nào?',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Chip(
                      avatar: const Icon(
                        Icons.local_fire_department_rounded,
                        size: 18,
                      ),
                      label: Text('${data.streak} ngày'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data.today == null
                      ? 'Chọn cảm xúc gần nhất với bạn lúc này.'
                      : 'Bạn có thể sửa check-in trong ngày bất cứ lúc nào.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children:
                          Mood.values.map((mood) {
                            final isSelected = mood == selected;
                            return ChoiceChip(
                              selected: isSelected,
                              onSelected:
                                  (_) => setState(() => _selectedMood = mood),
                              avatar: Text(mood.symbol),
                              label: Text(mood.label),
                            );
                          }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mức năng lượng',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _energyLevel == null
                              ? 'Không bắt buộc'
                              : '${_energyLevel!.round()}/5',
                        ),
                        Slider(
                          value: _energyLevel ?? 3,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          onChanged:
                              (value) => setState(() => _energyLevel = value),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                _energyLevel == null
                                    ? null
                                    : () => setState(() => _energyLevel = null),
                            child: const Text('Bỏ chọn'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Một dòng cho hôm nay (không bắt buộc)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: selected == null ? null : _save,
                  icon: const Icon(Icons.favorite_rounded),
                  label: Text(
                    data.today == null ? 'Lưu check-in' : 'Cập nhật check-in',
                  ),
                ),
                const MissionsSection(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48),
            const SizedBox(height: 12),
            const Text('Chưa thể tải dữ liệu của bạn.'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
