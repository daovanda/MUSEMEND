import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/core/presentation/catalog_artwork.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/features/missions/application/mission_providers.dart';
import 'package:musemend/features/missions/domain/mission_dashboard.dart';
import 'package:musemend/features/missions/domain/mission_template.dart';
import 'package:musemend/features/missions/domain/mission_type.dart';
import 'package:musemend/features/missions/domain/user_mission.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

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
    final strings = AppLocalizations.of(context);
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
                      Text(strings.missionLoadFailed),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed:
                            () => ref.invalidate(missionsControllerProvider),
                        child: Text(strings.retry),
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
                            strings.missionToday,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Text(
                          strings.missionTaskCount(dashboard.missions.length),
                        ),
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
                      label: Text(strings.missionCreateNew),
                    ),
                  ],
                  if (!skyStyle) ...[
                    const SizedBox(height: 24),
                    Text(
                      strings.missionMuseSuggestions,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.missionSuggestionsDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    if (dashboard.suggestions.isEmpty)
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Text(strings.missionSuggestionsEmpty),
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
    final strings = AppLocalizations.of(context);
    final result = await ref
        .read(missionsControllerProvider.notifier)
        .complete(mission.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == null
              ? strings.missionCompleteFailed
              : result.alreadyCompleted
              ? strings.missionAlreadyCompleted
              : strings.missionRewardReceived(result.reward),
        ),
      ),
    );
  }

  Future<void> _skip(
    BuildContext context,
    WidgetRef ref,
    UserMission mission,
  ) async {
    final strings = AppLocalizations.of(context);
    final succeeded = await ref
        .read(missionsControllerProvider.notifier)
        .skip(mission.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded ? strings.missionSkipped : strings.missionSkipFailed,
        ),
      ),
    );
  }

  Future<void> _addTemplate(
    BuildContext context,
    WidgetRef ref,
    MissionTemplate template,
  ) async {
    final strings = AppLocalizations.of(context);
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
          succeeded ? strings.missionAdded : strings.missionAddFailed,
        ),
      ),
    );
  }

  Future<void> _showCreateCustom(BuildContext context, WidgetRef ref) async {
    final strings = AppLocalizations.of(context);
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
          succeeded ? strings.missionCustomAdded : strings.missionCreateFailed,
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
    final strings = AppLocalizations.of(context);
    final grouped = <_MissionPeriod, List<UserMission>>{
      for (final period in _MissionPeriod.values) period: [],
    };
    for (final mission in dashboard.missions) {
      if (mission.missionType == MissionType.daily) {
        grouped[_periodFor(mission)]!.add(mission);
      }
    }
    final groupedByType = <MissionType, List<UserMission>>{
      for (final type in const [
        MissionType.weekly,
        MissionType.monthly,
        MissionType.yearly,
        MissionType.custom,
      ])
        type: dashboard.missions
            .where((mission) => mission.missionType == type)
            .toList(growable: false),
    };
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
              Positioned(
                top: 0,
                left: 0,
                child: Text(
                  strings.missionCareToday,
                  style: const TextStyle(
                    color: Color(0xFF384143),
                    fontSize: 24,
                    height: 1.02,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.5,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 8,
                right: 102,
                child: Text(
                  strings.missionGentleStep,
                  maxLines: 2,
                  style: const TextStyle(
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
        for (final period in _MissionPeriod.values)
          if (grouped[period]!.isNotEmpty)
            _SkyMissionGroup(
              label: _missionPeriodLabel(strings, period),
              missions: grouped[period]!,
              onComplete: onComplete,
              onSkip: onSkip,
              onCreate: onCreate,
            ),
        for (final entry in groupedByType.entries)
          if (entry.value.isNotEmpty)
            _SkyMissionGroup(
              label: strings.missionGroupType(
                _missionTypeLabel(strings, entry.key).toLowerCase(),
              ),
              missions: entry.value,
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
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 32,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              strings.missionMuseSuggestions,
              style: const TextStyle(
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
    final strings = AppLocalizations.of(context);
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
                    strings.missionSuggestionMeta(
                      _missionTypeLabel(strings, template.missionType),
                      template.estimatedMinutes ?? 1,
                      template.energyReward,
                    ),
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
            tooltip: strings.missionAddTemplate,
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

class _DynamicStickerPlaceholder extends StatelessWidget {
  const _DynamicStickerPlaceholder({this.assetPath});

  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).missionCurrentLandmarkSemantics,
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
    final strings = AppLocalizations.of(context);
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
                tooltip: strings.missionAddToGroup(label),
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
    final strings = AppLocalizations.of(context);
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
              Icons.spa_outlined,
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
                    _missionScheduleLabel(strings, mission),
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
            tooltip: strings.missionComplete,
            onPressed: onComplete,
            icon: const Icon(Icons.check_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5EA),
              foregroundColor: const Color(0xFF62766B),
            ),
          ),
          PopupMenuButton<void>(
            tooltip: strings.missionOptions,
            padding: EdgeInsets.zero,
            iconSize: 17,
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF778183)),
            itemBuilder:
                (context) => [
                  PopupMenuItem<void>(
                    onTap: onSkip,
                    child: Text(strings.missionSkip),
                  ),
                ],
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
    final strings = AppLocalizations.of(context);
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
                    strings.missionEnergyAccumulated,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(strings.missionEnergySummary(current, available)),
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
    final strings = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: strings.missionComplete,
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
                    _missionScheduleLabel(strings, mission),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(strings.missionEnergyReward(mission.energyReward)),
                ],
              ),
            ),
            IconButton(
              tooltip: strings.missionSkip,
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
    final strings = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Text('🌱')),
        title: Text(template.title),
        subtitle: Text(
          strings.missionSuggestionMeta(
            _missionTypeLabel(strings, template.missionType),
            template.estimatedMinutes ?? 1,
            template.energyReward,
          ),
        ),
        trailing: IconButton(
          tooltip: strings.missionAddAction,
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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text(AppLocalizations.of(context).missionEmpty),
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
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final strings = AppLocalizations.of(context);
    final viewport = MediaQuery.sizeOf(context);
    final template = widget.template;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: viewport.height * .9,
          maxWidth: 560,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16, 4, 16, 12 + viewInsets.bottom),
          child: MuseGlassCard(
            tint: MuseColors.sky,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.template == null
                              ? strings.missionCustomSheetTitle
                              : strings.missionSuggestionSheetTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: strings.close,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template == null
                        ? strings.missionCustomRewardDescription
                        : strings.missionSuggestionPrepared,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (template == null) ...[
                    _MissionTypeField(
                      value: _missionType,
                      onChanged:
                          (value) => setState(() => _missionType = value),
                    ),
                    const SizedBox(height: 10),
                    _FieldLabel(label: strings.missionName),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _titleController,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: strings.missionNameHint,
                        prefixIcon: const Icon(Icons.spa_outlined),
                        isDense: true,
                        counterText: '',
                      ),
                      validator: (value) {
                        final length = value?.trim().length ?? 0;
                        return length < 1 || length > 200
                            ? strings.missionNameValidation
                            : null;
                      },
                    ),
                    const SizedBox(height: 8),
                    _FieldLabel(label: strings.missionNoteOptional),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _descriptionController,
                      maxLength: 500,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: strings.missionNoteHint,
                        prefixIcon: const Icon(Icons.notes_rounded),
                        isDense: true,
                        counterText: '',
                      ),
                    ),
                  ] else
                    _TemplateMissionSummary(
                      template: template,
                      missionType: _missionType,
                    ),
                  const SizedBox(height: 8),
                  _SectionCaption(
                    icon: Icons.schedule_rounded,
                    label: strings.missionSchedule,
                  ),
                  const SizedBox(height: 6),
                  ..._scheduleFields(context),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(strings.missionAddAction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _scheduleFields(BuildContext context) {
    final strings = AppLocalizations.of(context);
    switch (_missionType) {
      case MissionType.daily:
        return [
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: strings.missionStart,
                  value: _dailyStart,
                  onChanged: (value) => setState(() => _dailyStart = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeField(
                  label: strings.missionEnd,
                  value: _dailyEnd,
                  onChanged: (value) => setState(() => _dailyEnd = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            strings.missionDailyRenewal(
              _periodLabelForTime(strings, _dailyStart),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ];
      case MissionType.weekly:
        return [
          _ScheduleInfo(
            icon: Icons.date_range_rounded,
            label: strings.missionWeeklyEnd,
          ),
        ];
      case MissionType.monthly:
        return [
          _ScheduleInfo(
            icon: Icons.calendar_view_month_rounded,
            label: strings.missionMonthlyEnd,
          ),
        ];
      case MissionType.yearly:
        return [
          _ScheduleInfo(
            icon: Icons.event_available_outlined,
            label: strings.missionYearlyEnd,
          ),
        ];
      case MissionType.custom:
        return [
          _DateTimeField(
            label: strings.missionStart,
            date: _customStartDate,
            time: _customStartTime,
            onDateChanged: (value) => setState(() => _customStartDate = value),
            onTimeChanged: (value) => setState(() => _customStartTime = value),
          ),
          const SizedBox(height: 10),
          _DateTimeField(
            label: strings.missionEnd,
            date: _customEndDate,
            time: _customEndTime,
            onDateChanged: (value) => setState(() => _customEndDate = value),
            onTimeChanged: (value) => setState(() => _customEndTime = value),
          ),
        ];
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    DateTime? startAt;
    DateTime? dueAt;
    if (_missionType == MissionType.daily) {
      if (_minutes(_dailyEnd) <= _minutes(_dailyStart)) {
        _showValidation(AppLocalizations.of(context).missionEndTimeAfterStart);
        return;
      }
      final today = _vietnamToday();
      startAt = _vietnamInstant(today, _dailyStart);
      dueAt = _vietnamInstant(today, _dailyEnd);
      if (!dueAt.isAfter(DateTime.now().toUtc())) {
        _showValidation(AppLocalizations.of(context).missionEndTimeFuture);
        return;
      }
    } else if (_missionType == MissionType.custom) {
      startAt = _vietnamInstant(_customStartDate, _customStartTime);
      dueAt = _vietnamInstant(_customEndDate, _customEndTime);
      if (!dueAt.isAfter(startAt) || !dueAt.isAfter(DateTime.now().toUtc())) {
        _showValidation(AppLocalizations.of(context).missionEndDateFuture);
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

class _TimeField extends StatefulWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatTime(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _TimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = _formatTime(widget.value);
    if (!_focusNode.hasFocus && _controller.text != nextText) {
      _controller.text = nextText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 4),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: MuseColors.ink.withValues(alpha: .78),
            ),
          ),
        ),
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
            LengthLimitingTextInputFormatter(5),
          ],
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.schedule_rounded),
            hintText: 'HH:mm',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
          validator:
              (value) =>
                  _parseTime(value) == null
                      ? AppLocalizations.of(context).missionTimeFormat
                      : null,
          onChanged: (value) {
            final parsed = _parseTime(value);
            if (parsed != null) widget.onChanged(parsed);
          },
          onFieldSubmitted: (value) {
            final parsed = _parseTime(value);
            if (parsed != null) _controller.text = _formatTime(parsed);
          },
        ),
      ],
    );
  }
}

class _DateField extends StatefulWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatDate(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _DateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = _formatDate(widget.value);
    if (!_focusNode.hasFocus && _controller.text != nextText) {
      _controller.text = nextText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 4),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: MuseColors.ink.withValues(alpha: .78),
            ),
          ),
        ),
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.calendar_today_outlined),
            hintText: 'dd/MM/yyyy',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
          validator: (value) {
            final parsed = _parseDate(value);
            if (parsed == null) {
              return AppLocalizations.of(context).missionDateFormat;
            }
            if (parsed.isBefore(_vietnamToday())) {
              return AppLocalizations.of(context).missionDateNotPast;
            }
            return null;
          },
          onChanged: (value) {
            final parsed = _parseDate(value);
            if (parsed != null && !parsed.isBefore(_vietnamToday())) {
              widget.onChanged(parsed);
            }
          },
          onFieldSubmitted: (value) {
            final parsed = _parseDate(value);
            if (parsed != null && !parsed.isBefore(_vietnamToday())) {
              _controller.text = _formatDate(parsed);
            }
          },
        ),
      ],
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.date,
    required this.time,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  final String label;
  final DateTime date;
  final TimeOfDay time;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _DateField(
            label: strings.missionDateField(label),
            value: date,
            onChanged: onDateChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TimeField(
            label: strings.missionTimeField(label),
            value: time,
            onChanged: onTimeChanged,
          ),
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
          Icon(icon, size: 18, color: MuseColors.ink),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: MuseColors.ink.withValues(alpha: .78),
        ),
      ),
    );
  }
}

class _MissionTypeField extends StatelessWidget {
  const _MissionTypeField({required this.value, required this.onChanged});

  final MissionType value;
  final ValueChanged<MissionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.missionType,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final type in MissionType.values)
              ChoiceChip(
                label: Text(_missionTypeLabel(strings, type)),
                selected: type == value,
                onSelected: (_) => onChanged(type),
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                backgroundColor: Colors.white.withValues(alpha: .5),
                selectedColor: MuseColors.teal.withValues(alpha: .18),
                side: BorderSide(
                  color:
                      type == value
                          ? MuseColors.teal.withValues(alpha: .72)
                          : Colors.white.withValues(alpha: .82),
                ),
                shape: const StadiumBorder(),
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: type == value ? MuseColors.teal : MuseColors.ink,
                  fontWeight: type == value ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TemplateMissionSummary extends StatelessWidget {
  const _TemplateMissionSummary({
    required this.template,
    required this.missionType,
  });

  final MissionTemplate template;
  final MissionType missionType;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _SummaryPill(
              icon: Icons.calendar_month_outlined,
              label: _missionTypeLabel(strings, missionType),
            ),
            _SummaryPill(
              icon: Icons.air_rounded,
              label: strings.missionEnergyReward(template.energyReward),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _TemplateDetail(
          icon: Icons.spa_outlined,
          label: strings.missionName,
          value: template.title,
        ),
        if (template.description?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 8),
          _TemplateDetail(
            icon: Icons.notes_rounded,
            label: strings.missionNoteOptional,
            value: template.description!.trim(),
          ),
        ],
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: ShapeDecoration(
        color: MuseColors.teal.withValues(alpha: .13),
        shape: StadiumBorder(
          side: BorderSide(color: MuseColors.teal.withValues(alpha: .42)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: MuseColors.teal),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: MuseColors.teal,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateDetail extends StatelessWidget {
  const _TemplateDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .52),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .76)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: MuseColors.ink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: MuseColors.ink.withValues(alpha: .72),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MuseColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCaption extends StatelessWidget {
  const _SectionCaption({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: MuseColors.teal),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: MuseColors.teal,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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

String _periodLabelForTime(AppLocalizations strings, TimeOfDay time) {
  if (time.hour >= 5 && time.hour < 12) return strings.missionPeriodMorning;
  if (time.hour >= 12 && time.hour < 17) {
    return strings.missionPeriodAfternoon;
  }
  if (time.hour >= 17 && time.hour < 22) return strings.missionPeriodEvening;
  return strings.missionPeriodAnytime;
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().padLeft(4, '0')}';

DateTime? _parseDate(String? input) {
  final match = RegExp(
    r'^(\d{2})/(\d{2})/(\d{4})$',
  ).firstMatch(input?.trim() ?? '');
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31) return null;
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

String _formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

TimeOfDay? _parseTime(String? input) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(input?.trim() ?? '');
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _missionScheduleLabel(AppLocalizations strings, UserMission mission) {
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
  if (due != null) return strings.missionDue(date(due));
  return _missionTypeLabel(strings, mission.missionType);
}

String _missionTypeLabel(AppLocalizations strings, MissionType type) =>
    switch (type) {
      MissionType.daily => strings.missionTypeDaily,
      MissionType.weekly => strings.missionTypeWeekly,
      MissionType.monthly => strings.missionTypeMonthly,
      MissionType.yearly => strings.missionTypeYearly,
      MissionType.custom => strings.missionTypeCustom,
    };

String _missionPeriodLabel(AppLocalizations strings, _MissionPeriod period) =>
    switch (period) {
      _MissionPeriod.morning => strings.missionPeriodMorning,
      _MissionPeriod.afternoon => strings.missionPeriodAfternoon,
      _MissionPeriod.evening => strings.missionPeriodEvening,
      _MissionPeriod.anytime => strings.missionPeriodAnytime,
    };
