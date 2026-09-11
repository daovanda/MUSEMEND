import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/core/presentation/catalog_artwork.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/features/missions/application/mission_providers.dart';
import 'package:musemend/features/missions/domain/mission_dashboard.dart';
import 'package:musemend/features/missions/domain/mission_template.dart';
import 'package:musemend/features/missions/domain/mission_type.dart';
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
        if (!skyStyle) const SizedBox(height: 28),
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
                        onAddTemplate:
                            (template) => _addTemplate(context, ref, template),
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
    final draft = await showModalBottomSheet<_MissionDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66366672),
      showDragHandle: true,
      builder: (context) => _CreateMissionSheet(template: template),
    );
    if (draft == null || !context.mounted) return;
    final succeeded = await ref
        .read(missionsControllerProvider.notifier)
        .addTemplate(template, startAt: draft.startAt, dueAt: draft.dueAt);
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
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66366672),
      showDragHandle: true,
      builder: (context) => const _CreateMissionSheet(),
    );
    if (draft == null || !context.mounted) return;
    final succeeded = await ref
        .read(missionsControllerProvider.notifier)
        .createScheduled(
          missionType: draft.missionType,
          title: draft.title,
          description: draft.description,
          startAt: draft.startAt,
          dueAt: draft.dueAt,
        );
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
    required this.onAddTemplate,
    required this.onComplete,
    required this.onSkip,
    required this.onCreate,
  });

  final MissionDashboard dashboard;
  final int? energyEarned;
  final int? energyRequired;
  final String? artworkPath;
  final ValueChanged<MissionTemplate> onAddTemplate;
  final ValueChanged<UserMission> onComplete;
  final ValueChanged<UserMission> onSkip;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final grouped = <_MissionPeriod, List<UserMission>>{
      for (final period in _MissionPeriod.values) period: [],
    };
    for (final mission in dashboard.missions) {
      if (mission.missionType == MissionType.daily) {
        grouped[_periodFor(mission)]!.add(mission);
      }
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
        for (final type in const [
          MissionType.weekly,
          MissionType.monthly,
          MissionType.yearly,
          MissionType.custom,
        ])
          _SkyMissionGroup(
            label: 'Nhiệm vụ ${type.label.toLowerCase()}',
            missions: dashboard.missions
                .where((mission) => mission.missionType == type)
                .toList(growable: false),
            onComplete: onComplete,
            onSkip: onSkip,
            onCreate: onCreate,
          ),
        if (dashboard.suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          _SkySuggestionGroup(
            suggestions: dashboard.suggestions,
            onAdd: onAddTemplate,
          ),
        ],
      ],
    );
  }

  _MissionPeriod _periodFor(UserMission mission) {
    final vietnamHour =
        mission.startAt.toUtc().add(const Duration(hours: 7)).hour;
    if (vietnamHour >= 5 && vietnamHour < 12) {
      return _MissionPeriod.morning;
    }
    if (vietnamHour >= 12 && vietnamHour < 17) {
      return _MissionPeriod.afternoon;
    }
    if (vietnamHour >= 17 && vietnamHour < 22) {
      return _MissionPeriod.evening;
    }
    return _MissionPeriod.anytime;
  }
}

class _SkySuggestionGroup extends StatelessWidget {
  const _SkySuggestionGroup({required this.suggestions, required this.onAdd});

  final List<MissionTemplate> suggestions;
  final ValueChanged<MissionTemplate> onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: 32,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Gợi ý từ Muse',
              style: TextStyle(
                color: Color(0xFF526164),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        for (final suggestion in suggestions)
          _SkySuggestionRow(
            template: suggestion,
            onAdd: () => onAdd(suggestion),
          ),
      ],
    );
  }
}

class _SkySuggestionRow extends StatelessWidget {
  const _SkySuggestionRow({required this.template, required this.onAdd});

  final MissionTemplate template;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .72)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xBDF2F7F3),
            child: Icon(Icons.spa_outlined, size: 16, color: Color(0xFF627B76)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF435154),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${template.missionType.label} · ${template.estimatedMinutes ?? 1} phút · +${template.energyReward} năng lượng',
                    style: const TextStyle(
                      color: Color(0xFF7B8586),
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Thêm nhiệm vụ mẫu',
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
            color: const Color(0xFF627B76),
          ),
        ],
      ),
    );
  }
}

enum _MissionPeriod { morning, afternoon, evening, anytime }

const _missionPeriodLabels = <_MissionPeriod, String>{
  _MissionPeriod.morning: 'Buổi sáng',
  _MissionPeriod.afternoon: 'Buổi chiều',
  _MissionPeriod.evening: 'Buổi tối',
  _MissionPeriod.anytime: 'Bất kỳ lúc nào',
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
                  Text(
                    _missionScheduleLabel(mission),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF728285),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
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
                  Text(
                    _missionScheduleLabel(mission),
                    style: Theme.of(context).textTheme.bodySmall,
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
          '${template.missionType.label} · ${template.estimatedMinutes ?? 1} phút · +${template.energyReward} năng lượng',
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
  const _MissionDraft({
    required this.missionType,
    required this.title,
    required this.description,
    required this.startAt,
    required this.dueAt,
  });

  final MissionType missionType;
  final String title;
  final String? description;
  final DateTime? startAt;
  final DateTime? dueAt;
}

class _CreateMissionSheet extends StatefulWidget {
  const _CreateMissionSheet({this.template});

  final MissionTemplate? template;

  @override
  State<_CreateMissionSheet> createState() => _CreateMissionSheetState();
}

class _CreateMissionSheetState extends State<_CreateMissionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late MissionType _missionType;
  TimeOfDay _dailyStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _dailyEnd = const TimeOfDay(hour: 10, minute: 0);
  late DateTime _customStartDate;
  late DateTime _customEndDate;
  TimeOfDay _customStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _customEndTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    final today = _vietnamToday();
    final vietnamNow = DateTime.now().toUtc().add(const Duration(hours: 7));
    final startMinutes = (vietnamNow.hour * 60 + vietnamNow.minute).clamp(
      0,
      1438,
    );
    final endMinutes = (startMinutes + 60).clamp(1, 1439);
    _dailyStart = TimeOfDay(
      hour: startMinutes ~/ 60,
      minute: startMinutes % 60,
    );
    _dailyEnd = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
    _missionType = widget.template?.missionType ?? MissionType.daily;
    _customStartDate = today;
    _customEndDate = today.add(const Duration(days: 1));
    _customStartTime = _dailyStart;
    _customEndTime = _dailyEnd;
    if (widget.template case final template?) {
      _titleController.text = template.title;
      _descriptionController.text = template.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: MuseGlassCard(
          tint: MuseColors.sky,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.template == null
                      ? 'Nhiệm vụ của bạn'
                      : 'Thêm gợi ý từ Muse',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mỗi nhiệm vụ tự tạo được thưởng cố định 5 năng lượng.',
                ),
                const SizedBox(height: 16),
                if (widget.template == null)
                  DropdownButtonFormField<MissionType>(
                    value: _missionType,
                    decoration: const InputDecoration(
                      labelText: 'Loại nhiệm vụ',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    items: [
                      for (final type in MissionType.values)
                        DropdownMenuItem(value: type, child: Text(type.label)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _missionType = value);
                      }
                    },
                  )
                else
                  _ScheduleInfo(
                    icon: Icons.category_outlined,
                    label: 'Loại: ${_missionType.label}',
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  readOnly: widget.template != null,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Tên nhiệm vụ',
                    prefixIcon: Icon(Icons.spa_outlined),
                  ),
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
                  readOnly: widget.template != null,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú (không bắt buộc)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 4),
                ..._scheduleFields(context),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Thêm nhiệm vụ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _scheduleFields(BuildContext context) {
    switch (_missionType) {
      case MissionType.daily:
        return [
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: 'Bắt đầu',
                  value: _dailyStart,
                  onTap: () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeField(
                  label: 'Kết thúc',
                  value: _dailyEnd,
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Được xếp vào ${_periodLabelForTime(_dailyStart)} và tự làm mới mỗi ngày.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ];
      case MissionType.weekly:
        return const [
          _ScheduleInfo(
            icon: Icons.date_range_rounded,
            label: 'Kết thúc lúc 00:00 đầu tuần kế tiếp.',
          ),
        ];
      case MissionType.monthly:
        return const [
          _ScheduleInfo(
            icon: Icons.calendar_view_month_rounded,
            label: 'Kết thúc lúc 00:00 ngày đầu tháng kế tiếp.',
          ),
        ];
      case MissionType.yearly:
        return const [
          _ScheduleInfo(
            icon: Icons.event_available_outlined,
            label: 'Kết thúc lúc 00:00 ngày đầu năm kế tiếp.',
          ),
        ];
      case MissionType.custom:
        return [
          _DateTimeField(
            label: 'Bắt đầu',
            date: _customStartDate,
            time: _customStartTime,
            onDateTap: () => _pickDate(true),
            onTimeTap: () => _pickCustomTime(true),
          ),
          const SizedBox(height: 10),
          _DateTimeField(
            label: 'Kết thúc',
            date: _customEndDate,
            time: _customEndTime,
            onDateTap: () => _pickDate(false),
            onTimeTap: () => _pickCustomTime(false),
          ),
        ];
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? _dailyStart : _dailyEnd,
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isStart) {
        _dailyStart = selected;
      } else {
        _dailyEnd = selected;
      }
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final today = _vietnamToday();
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart ? _customStartDate : _customEndDate,
      firstDate: today,
      lastDate: DateTime(today.year + 10, 12, 31),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isStart) {
        _customStartDate = selected;
      } else {
        _customEndDate = selected;
      }
    });
  }

  Future<void> _pickCustomTime(bool isStart) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? _customStartTime : _customEndTime,
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isStart) {
        _customStartTime = selected;
      } else {
        _customEndTime = selected;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    DateTime? startAt;
    DateTime? dueAt;
    if (_missionType == MissionType.daily) {
      if (_minutes(_dailyEnd) <= _minutes(_dailyStart)) {
        _showValidation('Giờ kết thúc phải sau giờ bắt đầu trong cùng ngày.');
        return;
      }
      final today = _vietnamToday();
      startAt = _vietnamInstant(today, _dailyStart);
      dueAt = _vietnamInstant(today, _dailyEnd);
      if (!dueAt.isAfter(DateTime.now().toUtc())) {
        _showValidation('Giờ kết thúc phải ở sau thời điểm hiện tại.');
        return;
      }
    } else if (_missionType == MissionType.custom) {
      startAt = _vietnamInstant(_customStartDate, _customStartTime);
      dueAt = _vietnamInstant(_customEndDate, _customEndTime);
      if (!dueAt.isAfter(startAt) || !dueAt.isAfter(DateTime.now().toUtc())) {
        _showValidation(
          'Thời gian kết thúc phải ở tương lai và sau lúc bắt đầu.',
        );
        return;
      }
    }
    final description = _descriptionController.text.trim();
    Navigator.of(context).pop(
      _MissionDraft(
        missionType: _missionType,
        title: _titleController.text.trim(),
        description: description.isEmpty ? null : description,
        startAt: startAt,
        dueAt: dueAt,
      ),
    );
  }

  void _showValidation(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.schedule_rounded),
      label: Text('$label\n${value.format(context)}'),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.date,
    required this.time,
    required this.onDateTap,
    required this.onTimeTap,
  });

  final String label;
  final DateTime date;
  final TimeOfDay time;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDateTap,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('${date.day}/${date.month}/${date.year}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onTimeTap,
                icon: const Icon(Icons.schedule_rounded),
                label: Text(time.format(context)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScheduleInfo extends StatelessWidget {
  const _ScheduleInfo({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .58),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: MuseColors.ink),
          const SizedBox(width: 9),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

DateTime _vietnamToday() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 7));
  return DateTime(now.year, now.month, now.day);
}

DateTime _vietnamInstant(DateTime date, TimeOfDay time) {
  return DateTime.utc(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  ).subtract(const Duration(hours: 7));
}

String _periodLabelForTime(TimeOfDay time) {
  if (time.hour >= 5 && time.hour < 12) return 'Buổi sáng';
  if (time.hour >= 12 && time.hour < 17) return 'Buổi chiều';
  if (time.hour >= 17 && time.hour < 22) return 'Buổi tối';
  return 'Bất kỳ lúc nào';
}

String _missionScheduleLabel(UserMission mission) {
  final start = mission.startAt.toUtc().add(const Duration(hours: 7));
  final due = mission.dueAt?.toUtc().add(const Duration(hours: 7));
  String clock(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  String date(DateTime value) => '${value.day}/${value.month}/${value.year}';

  if (mission.missionType == MissionType.daily && due != null) {
    return '${clock(start)}–${clock(due)}';
  }
  if (mission.missionType == MissionType.custom && due != null) {
    return '${date(start)} ${clock(start)} → ${date(due)} ${clock(due)}';
  }
  if (due != null) return 'Hạn ${date(due)}';
  return mission.missionType.label;
}
