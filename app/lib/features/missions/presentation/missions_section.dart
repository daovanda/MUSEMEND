import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/features/missions/application/mission_providers.dart';
import 'package:musemend/features/missions/domain/mission_dashboard.dart';
import 'package:musemend/features/missions/domain/mission_template.dart';
import 'package:musemend/features/missions/domain/user_mission.dart';

class MissionsSection extends ConsumerWidget {
  const MissionsSection({this.skyStyle = false, super.key});

  /// Uses the rounded, grouped presentation from the Figma sky frame while
  /// keeping the same server-backed mission actions and default presentation.
  final bool skyStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(missionsControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        state.when(
          loading:
              () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          error:
              (_, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Chưa thể tải nhiệm vụ.'),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed:
                            () => ref.invalidate(missionsControllerProvider),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
          data:
              (dashboard) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!skyStyle)
                    _EnergyCard(
                      current: dashboard.energy.currentEnergy,
                      available: dashboard.energy.availableEnergy,
                    ),
                  if (!skyStyle) const SizedBox(height: 20),
                  if (skyStyle)
                    _SkyMissionPanel(
                      dashboard: dashboard,
                      onComplete: (mission) => _complete(context, ref, mission),
                      onSkip: (mission) => _skip(context, ref, mission),
                      onCreate: () => _showCreateCustom(context, ref),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Nhiệm vụ hôm nay',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Text('${dashboard.missions.length} việc'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (dashboard.missions.isEmpty)
                      const _EmptyMissions()
                    else
                      ...dashboard.missions.map(
                        (mission) => _MissionCard(
                          mission: mission,
                          onComplete: () => _complete(context, ref, mission),
                          onSkip: () => _skip(context, ref, mission),
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showCreateCustom(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tự tạo nhiệm vụ mới'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Gợi ý từ Muse',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Những bước nhỏ phù hợp với cảm xúc hôm nay.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  if (dashboard.suggestions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('Bạn đã thêm hết gợi ý phù hợp hôm nay.'),
                      ),
                    )
                  else
                    ...dashboard.suggestions
                        .take(5)
                        .map(
                          (template) => _SuggestionCard(
                            template: template,
                            onAdd: () => _addTemplate(context, ref, template),
                          ),
                        ),
                ],
              ),
        ),
      ],
    );
  }

  Future<void> _complete(
    BuildContext context,
    WidgetRef ref,
    UserMission mission,
  ) async {
    final result = await ref
        .read(missionsControllerProvider.notifier)
        .complete(mission.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == null
              ? 'Chưa thể hoàn thành nhiệm vụ. Hãy thử lại.'
              : result.alreadyCompleted
              ? 'Nhiệm vụ này đã được ghi nhận trước đó.'
              : 'Bạn đã nhận ${result.reward} năng lượng.',
        ),
      ),
    );
  }

  Future<void> _skip(
    BuildContext context,
    WidgetRef ref,
    UserMission mission,
  ) async {
    final succeeded = await ref
        .read(missionsControllerProvider.notifier)
        .skip(mission.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? 'Đã bỏ qua nhiệm vụ, không trừ năng lượng.'
              : 'Chưa thể bỏ qua nhiệm vụ.',
        ),
      ),
    );
  }

  Future<void> _addTemplate(
    BuildContext context,
    WidgetRef ref,
    MissionTemplate template,
  ) async {
    final succeeded = await ref
        .read(missionsControllerProvider.notifier)
        .addTemplate(template);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded ? 'Đã thêm nhiệm vụ.' : 'Chưa thể thêm nhiệm vụ.',
        ),
      ),
    );
  }

  Future<void> _showCreateCustom(BuildContext context, WidgetRef ref) async {
    final draft = await showModalBottomSheet<_MissionDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CreateMissionSheet(),
    );
    if (draft == null || !context.mounted) return;
    final succeeded = await ref
        .read(missionsControllerProvider.notifier)
        .createCustom(title: draft.title, description: draft.description);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? 'Đã thêm nhiệm vụ riêng với phần thưởng 5 năng lượng.'
              : 'Chưa thể tạo nhiệm vụ.',
        ),
      ),
    );
  }
}

class _SkyMissionPanel extends StatelessWidget {
  const _SkyMissionPanel({
    required this.dashboard,
    required this.onComplete,
    required this.onSkip,
    required this.onCreate,
  });

  final MissionDashboard dashboard;
  final ValueChanged<UserMission> onComplete;
  final ValueChanged<UserMission> onSkip;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .75)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chăm sóc hôm nay',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Một việc nhỏ cũng là cách cậu ở bên mình.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}  +',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: MuseColors.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (dashboard.missions.isEmpty)
            const _EmptyMissions()
          else
            ...dashboard.missions.map(
              (mission) => _SkyMissionRow(
                mission: mission,
                onComplete: () => onComplete(mission),
                onSkip: () => onSkip(mission),
              ),
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm một việc dịu dàng'),
              style: TextButton.styleFrom(
                foregroundColor: MuseColors.ink,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkyMissionRow extends StatelessWidget {
  const _SkyMissionRow({
    required this.mission,
    required this.onComplete,
    required this.onSkip,
  });

  final UserMission mission;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .75),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Hoàn thành',
            onPressed: onComplete,
            icon: const Icon(Icons.radio_button_unchecked_rounded),
            color: MuseColors.mutedInk,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (mission.description case final description?)
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          Text(
            '+${mission.energyReward} ⚡',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: MuseColors.mutedInk,
            ),
          ),
          IconButton(
            tooltip: 'Bỏ qua',
            onPressed: onSkip,
            icon: const Icon(Icons.more_horiz_rounded),
            color: MuseColors.mutedInk,
          ),
        ],
      ),
    );
  }
}

class _EnergyCard extends StatelessWidget {
  const _EnergyCard({required this.current, required this.available});

  final int current;
  final int available;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: MuseColors.lavender.withValues(alpha: 0.82),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.air_rounded, color: MuseColors.coral),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Năng lượng tích lũy',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '$current tổng cộng · $available sẵn sàng cho hành trình',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.mission,
    required this.onComplete,
    required this.onSkip,
  });

  final UserMission mission;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Hoàn thành',
              onPressed: onComplete,
              icon: const Icon(Icons.radio_button_unchecked_rounded),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: MuseColors.ink),
                  ),
                  if (mission.description case final description?)
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text('+${mission.energyReward} năng lượng'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Bỏ qua',
              onPressed: onSkip,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.template, required this.onAdd});

  final MissionTemplate template;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Text('🌱')),
        title: Text(template.title),
        subtitle: Text(
          '${template.estimatedMinutes ?? 1} phút · +${template.energyReward} năng lượng',
        ),
        trailing: IconButton(
          tooltip: 'Thêm nhiệm vụ',
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_rounded),
        ),
      ),
    );
  }
}

class _EmptyMissions extends StatelessWidget {
  const _EmptyMissions();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text('Chưa có nhiệm vụ nào. Hãy chọn một bước thật nhẹ nhàng.'),
      ),
    );
  }
}

class _MissionDraft {
  const _MissionDraft({required this.title, required this.description});

  final String title;
  final String? description;
}

class _CreateMissionSheet extends StatefulWidget {
  const _CreateMissionSheet();

  @override
  State<_CreateMissionSheet> createState() => _CreateMissionSheetState();
}

class _CreateMissionSheetState extends State<_CreateMissionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nhiệm vụ của bạn',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Mỗi nhiệm vụ tự tạo được thưởng cố định 5 năng lượng.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              autofocus: true,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Tên nhiệm vụ'),
              validator: (value) {
                final length = value?.trim().length ?? 0;
                return length < 1 || length > 200
                    ? 'Tên nhiệm vụ cần từ 1 đến 200 ký tự.'
                    : null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (không bắt buộc)',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                final description = _descriptionController.text.trim();
                Navigator.of(context).pop(
                  _MissionDraft(
                    title: _titleController.text.trim(),
                    description: description.isEmpty ? null : description,
                  ),
                );
              },
              child: const Text('Thêm nhiệm vụ'),
            ),
          ],
        ),
      ),
    );
  }
}
