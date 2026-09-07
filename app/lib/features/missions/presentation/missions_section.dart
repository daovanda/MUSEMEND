import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/core/presentation/catalog_artwork.dart';
import 'package:musemend/features/missions/application/mission_providers.dart';
import 'package:musemend/features/missions/domain/mission_dashboard.dart';
import 'package:musemend/features/missions/domain/mission_template.dart';
import 'package:musemend/features/missions/domain/user_mission.dart';

class MissionsSection extends ConsumerWidget {
  const MissionsSection({
    this.skyStyle = false,
    this.skyEnergyEarned,
    this.skyEnergyRequired,
    this.skyArtworkPath,
    super.key,
  });

  /// Uses the rounded, grouped presentation from the Figma sky frame while
  /// keeping the same server-backed mission actions and default presentation.
  final bool skyStyle;
  final int? skyEnergyEarned;
  final int? skyEnergyRequired;
  final String? skyArtworkPath;

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
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0x66D9F3F5),
                            Color(0x55E4F1F2),
                            Color(0x55EDE4F7),
                          ],
                          stops: [0, .52, 1],
                        ),
                        border: Border.all(color: Color(0x55FFFFFF)),
                      ),
                      child: _SkyMissionPanel(
                        dashboard: dashboard,
                        energyEarned: skyEnergyEarned,
                        energyRequired: skyEnergyRequired,
                        artworkPath: skyArtworkPath,
                        onComplete:
                            (mission) => _complete(context, ref, mission),
                        onSkip: (mission) => _skip(context, ref, mission),
                        onCreate: () => _showCreateCustom(context, ref),
                      ),
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
                  if (!skyStyle) ...[
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
    required this.energyEarned,
    required this.energyRequired,
    required this.artworkPath,
    required this.onComplete,
    required this.onSkip,
    required this.onCreate,
  });

  final MissionDashboard dashboard;
  final int? energyEarned;
  final int? energyRequired;
  final String? artworkPath;
  final ValueChanged<UserMission> onComplete;
  final ValueChanged<UserMission> onSkip;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final grouped = <_MissionPeriod, List<UserMission>>{
      for (final period in _MissionPeriod.values) period: [],
    };
    for (final mission in dashboard.missions) {
      grouped[_periodFor(mission)]!.add(mission);
    }
    final progress =
        energyEarned == null || energyRequired == null
            ? '--/--'
            : '${energyEarned!.toString().padLeft(2, '0')}/${energyRequired!.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 112,
          child: Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                child: Text(
                  'Chăm sóc\nhôm nay',
                  style: TextStyle(
                    color: Color(0xFF384143),
                    fontSize: 24,
                    height: 1.02,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.5,
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                bottom: 8,
                right: 102,
                child: Text(
                  'Hãy dịu dàng với chính mình bằng một việc thật nhỏ.',
                  maxLines: 2,
                  style: TextStyle(
                    color: Color(0xFF697173),
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 4,
                child: _DynamicStickerPlaceholder(assetPath: artworkPath),
              ),
              Positioned(
                right: 1,
                bottom: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      progress,
                      style: const TextStyle(
                        color: Color(0xFF536A70),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.air_rounded,
                      size: 14,
                      color: Color(0xFF66828A),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final entry in _missionPeriodLabels.entries)
          _SkyMissionGroup(
            label: entry.value,
            missions: grouped[entry.key]!,
            onComplete: onComplete,
            onSkip: onSkip,
            onCreate: onCreate,
          ),
      ],
    );
  }

  _MissionPeriod _periodFor(UserMission mission) {
    final dueAt = mission.dueAt;
    if (dueAt == null) return _MissionPeriod.anytime;
    final vietnamHour = dueAt.toUtc().add(const Duration(hours: 7)).hour;
    if (vietnamHour < 12) return _MissionPeriod.morning;
    if (vietnamHour < 17) return _MissionPeriod.afternoon;
    return _MissionPeriod.evening;
  }
}

enum _MissionPeriod { morning, anytime, afternoon, evening }

const _missionPeriodLabels = <_MissionPeriod, String>{
  _MissionPeriod.morning: 'Buổi sáng',
  _MissionPeriod.anytime: 'Bất kỳ lúc nào',
  _MissionPeriod.afternoon: 'Buổi chiều',
  _MissionPeriod.evening: 'Buổi tối',
};

class _DynamicStickerPlaceholder extends StatelessWidget {
  const _DynamicStickerPlaceholder({this.assetPath});

  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Minh họa địa danh của trạm hiện tại',
      image: true,
      child: Container(
        width: 94,
        height: 80,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: .72),
              const Color(0xFFD5E8E2).withValues(alpha: .26),
              Colors.transparent,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: CatalogArtwork(
          assetPath: assetPath,
          width: 76,
          height: 66,
          placeholder: Icon(
            Icons.landscape_rounded,
            size: 62,
            color: const Color(0xFF72958B).withValues(alpha: .85),
          ),
        ),
      ),
    );
  }
}

class _SkyMissionGroup extends StatelessWidget {
  const _SkyMissionGroup({
    required this.label,
    required this.missions,
    required this.onComplete,
    required this.onSkip,
    required this.onCreate,
  });

  final String label;
  final List<UserMission> missions;
  final ValueChanged<UserMission> onComplete;
  final ValueChanged<UserMission> onSkip;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 32,
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF526164),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Thêm nhiệm vụ vào $label',
                onPressed: onCreate,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_rounded, size: 17),
                color: const Color(0xFF637174),
              ),
            ],
          ),
        ),
        for (final mission in missions)
          _SkyMissionRow(
            mission: mission,
            onComplete: () => onComplete(mission),
            onSkip: () => onSkip(mission),
          ),
        if (missions.isEmpty) const SizedBox(height: 3),
      ],
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
        color: Colors.white.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 9),
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFF2F7F3),
            child: Icon(
              _iconForMission(mission),
              size: 17,
              color: const Color(0xFF627B76),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF435154),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (mission.description case final description?)
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7B8586),
                        fontSize: 8,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${mission.energyReward}',
                style: const TextStyle(
                  color: Color(0xFF577077),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.air_rounded, size: 12, color: Color(0xFF6F898F)),
            ],
          ),
          IconButton(
            tooltip: 'Hoàn thành',
            onPressed: onComplete,
            icon: const Icon(Icons.check_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5EA),
              foregroundColor: const Color(0xFF62766B),
            ),
          ),
          PopupMenuButton<void>(
            tooltip: 'Tùy chọn nhiệm vụ',
            padding: EdgeInsets.zero,
            iconSize: 17,
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF778183)),
            itemBuilder:
                (context) => [
                  PopupMenuItem<void>(
                    onTap: onSkip,
                    child: const Text('Bỏ qua nhiệm vụ'),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  static IconData _iconForMission(UserMission mission) {
    final text = '${mission.title} ${mission.description ?? ''}'.toLowerCase();
    if (text.contains('nước') || text.contains('uống')) {
      return Icons.water_drop_outlined;
    }
    if (text.contains('đi bộ') || text.contains('vận động')) {
      return Icons.directions_walk_rounded;
    }
    if (text.contains('thở') || text.contains('thiền')) {
      return Icons.air_rounded;
    }
    return Icons.spa_outlined;
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
