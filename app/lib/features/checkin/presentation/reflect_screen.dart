import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/core/presentation/catalog_artwork.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/features/checkin/application/reflect_providers.dart';
import 'package:musemend/features/checkin/application/reflect_state.dart';
import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/checkin/presentation/mood_visuals.dart';
import 'package:musemend/features/checkin/presentation/sky_scene.dart';
import 'package:musemend/features/journey/application/journey_providers.dart';
import 'package:musemend/features/journey/domain/journey_checkpoint.dart';
import 'package:musemend/features/journey/domain/journey_dashboard.dart';
import 'package:musemend/features/missions/presentation/missions_section.dart';
import 'package:musemend/features/quotes/application/daily_quote_providers.dart';

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

  Future<bool> _save() async {
    final mood = _selectedMood;
    if (mood == null) return false;
    final succeeded = await ref
        .read(reflectControllerProvider.notifier)
        .save(
          mood: mood,
          energyLevel: _energyLevel?.round(),
          note: _noteController.text,
        );
    if (!mounted) return succeeded;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? 'Đã lưu check-in hôm nay.'
              : 'Chưa thể lưu. Vui lòng thử lại.',
        ),
      ),
    );
    return succeeded;
  }

  Future<void> _saveAndWrite() async {
    if (await _save() && mounted) context.go('/journal');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reflectControllerProvider);
    // Keep the retry state self-contained instead of starting a second
    // Supabase request while check-in data is unavailable.
    final journeyState =
        state.hasValue ? ref.watch(journeyControllerProvider) : null;
    state.whenData(_hydrate);

    return MusePageBackground(
      accent: MuseColors.sky,
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, _) => SafeArea(
              child: _ErrorView(
                onRetry: () => ref.invalidate(reflectControllerProvider),
              ),
            ),
        data: (data) {
          final selected = _selectedMood ?? data.today?.mood;
          final journey = journeyState?.asData?.value;
          final checkpoint = _currentCheckpoint(journey);
          return ListView(
            padding: const EdgeInsets.only(bottom: 34),
            children: [
              _HomeSkyHero(
                streak: data.streak,
                energy: journey?.currentEnergy,
                selectedMood: selected,
                journey: journey,
                hasExistingCheckin: data.today != null,
                onMoodSelected: (mood) => setState(() => _selectedMood = mood),
                onSave: selected == null ? null : _save,
                onSaveAndWrite: selected == null ? null : _saveAndWrite,
              ),
              MuseContentFrame(
                compactGutter: 14,
                regularGutter: 16,
                child: MissionsSection(
                  skyStyle: true,
                  skyEnergyEarned: checkpoint?.earnedEnergy,
                  skyEnergyRequired: checkpoint?.requiredEnergy,
                  skyArtworkPath:
                      checkpoint?.assetPath ??
                      journey?.destination?.coverAssetPath,
                ),
              ),
              MuseContentFrame(
                compactGutter: 16,
                regularGutter: 28,
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    const _SkyQuoteCard(),
                    const SizedBox(height: 24),
                    const _ShareMoments(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  JourneyCheckpoint? _currentCheckpoint(JourneyDashboard? journey) {
    final id = journey?.currentCheckpointId;
    if (id == null) return null;
    for (final checkpoint in journey?.destination?.checkpoints ?? const []) {
      if (checkpoint.id == id) return checkpoint;
    }
    return null;
  }
}

class _HomeSkyHero extends StatelessWidget {
  const _HomeSkyHero({
    required this.streak,
    required this.energy,
    required this.selectedMood,
    required this.journey,
    required this.hasExistingCheckin,
    required this.onMoodSelected,
    required this.onSave,
    required this.onSaveAndWrite,
  });

  final int streak;
  final int? energy;
  final Mood? selectedMood;
  final JourneyDashboard? journey;
  final bool hasExistingCheckin;
  final ValueChanged<Mood> onMoodSelected;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAndWrite;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: SkyScene()),
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00FBF9F5),
                    Color(0x22FBF9F5),
                    Color(0xCCFBF9F5),
                    MuseColors.cream,
                  ],
                  stops: [.58, .74, .93, 1],
                ),
              ),
            ),
          ),
        ),
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: MuseContentFrame(
                compactGutter: 16,
                regularGutter: 16,
                child: MuseTopBar(
                  trailing: _SkyStatus(streak: streak, energy: energy),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const CloudMascot(),
            const SizedBox(height: 11),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 29),
              child: _MoodCheckinCard(
                selected: selectedMood,
                hasExistingCheckin: hasExistingCheckin,
                onSelected: onMoodSelected,
                onSave: onSave,
                onSaveAndWrite: onSaveAndWrite,
              ),
            ),
            const SizedBox(height: 104),
            MuseContentFrame(
              compactGutter: 16,
              regularGutter: 16,
              child: _JourneyOverview(journey: journey),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ],
    );
  }
}

class _SkyStatus extends StatelessWidget {
  const _SkyStatus({required this.streak, this.energy});

  final int streak;
  final int? energy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${energy ?? 0} năng lượng, streak $streak ngày',
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .44),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withValues(alpha: .62)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFFF4C84A), size: 18),
            const SizedBox(width: 3),
            Text(
              '${energy ?? 0}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFE98A67),
              size: 17,
            ),
            const SizedBox(width: 3),
            Text(
              '$streak',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodCheckinCard extends StatelessWidget {
  const _MoodCheckinCard({
    required this.selected,
    required this.hasExistingCheckin,
    required this.onSelected,
    required this.onSave,
    required this.onSaveAndWrite,
  });

  final Mood? selected;
  final bool hasExistingCheckin;
  final ValueChanged<Mood> onSelected;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAndWrite;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(48),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 332,
          constraints: const BoxConstraints(minHeight: 179),
          padding: const EdgeInsets.fromLTRB(25, 17, 25, 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .60),
            borderRadius: BorderRadius.circular(48),
            border: Border.all(color: Colors.white.withValues(alpha: .50)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 18,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Ngày hôm nay có dịu dàng với cậu không?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF565C5E),
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              SizedBox(
                height: 93,
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 268,
                    height: 93,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final mood in _homeMoodOrder)
                          _MoodOption(
                            mood: mood,
                            selected: mood == selected,
                            onTap: () => onSelected(mood),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: _MoodActionButton(
                      label: 'LƯU NHANH',
                      semanticLabel:
                          hasExistingCheckin
                              ? 'Cập nhật check-in hôm nay'
                              : 'Lưu nhanh check-in hôm nay',
                      onPressed: onSave,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    flex: 3,
                    child: _MoodActionButton(
                      label: 'LƯU VÀ VIẾT TÂM TƯ',
                      onPressed: onSaveAndWrite,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _homeMoodOrder = [Mood.awful, Mood.sad, Mood.okay, Mood.good, Mood.great];

class _MoodOption extends StatelessWidget {
  const _MoodOption({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = mood.visual;
    final top = (93 - visual.height) / 2;
    return Positioned(
      left: visual.left,
      top: top,
      width: visual.width,
      height: visual.height,
      child: Transform.rotate(
        angle: visual.rotationDegrees * math.pi / 180,
        child: Semantics(
          button: true,
          selected: selected,
          label: visual.label,
          excludeSemantics: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: visual.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        selected ? const Color(0xFF6E8E92) : Colors.transparent,
                    width: selected ? 1.3 : 0,
                  ),
                  boxShadow:
                      selected
                          ? const [
                            BoxShadow(
                              color: Color(0x1F366672),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      visual.assetPath,
                      cacheWidth: 128,
                      width: visual.imageSize,
                      height: visual.imageSize,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 1),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        visual.label,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Color(0xFF5B6163),
                          fontSize: 6.8,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodActionButton extends StatelessWidget {
  const _MoodActionButton({
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final String label;
  final String? semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: AnimatedOpacity(
        opacity: onPressed == null ? .48 : 1,
        duration: const Duration(milliseconds: 160),
        child: Container(
          width: double.infinity,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4E2C7), Color(0x99E9F1E3), Color(0x33FFFFFF)],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: .80)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(999),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF596868),
                        fontSize: 7.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyOverview extends StatelessWidget {
  const _JourneyOverview({required this.journey});

  final JourneyDashboard? journey;

  @override
  Widget build(BuildContext context) {
    final destination = journey?.destination;
    final checkpoints = destination?.checkpoints ?? const [];
    var currentNumber =
        (checkpoints.where((checkpoint) => checkpoint.isCompleted).length + 1)
            .clamp(1, checkpoints.isEmpty ? 1 : checkpoints.length);
    for (final checkpoint in checkpoints) {
      if (checkpoint.isCurrent) {
        currentNumber = checkpoint.number;
        break;
      }
    }
    return Semantics(
      label:
          'Hành trình ${destination?.name ?? 'đang chờ'}, trạm $currentNumber trên ${checkpoints.length}',
      child: SizedBox(
        height: 142,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  (destination?.name ?? 'HÀNH TRÌNH').toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF343B3D),
                    fontSize: 16,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Trạm',
                      style: TextStyle(
                        color: Color(0xFF697173),
                        fontSize: 9,
                        height: 1,
                      ),
                    ),
                    Text(
                      checkpoints.isEmpty
                          ? '--/--'
                          : '$currentNumber/${checkpoints.length}',
                      style: const TextStyle(
                        color: Color(0xFF535D5F),
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (checkpoints.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Hành trình sẽ xuất hiện khi dữ liệu trạm sẵn sàng.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF697173)),
                  ),
                ),
              )
            else
              Expanded(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      top: 23,
                      left: 24,
                      right: 24,
                      child: Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: .76),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final checkpoint in checkpoints.take(5))
                          Expanded(
                            child: _CheckpointDot(checkpoint: checkpoint),
                          ),
                      ],
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

class _CheckpointDot extends StatelessWidget {
  const _CheckpointDot({required this.checkpoint});

  final JourneyCheckpoint checkpoint;

  @override
  Widget build(BuildContext context) {
    final active = checkpoint.isCurrent || checkpoint.isCompleted;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color:
                active
                    ? Colors.white.withValues(alpha: .86)
                    : Colors.white.withValues(alpha: .48),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  checkpoint.isCurrent
                      ? const Color(0xFF6C9B7A)
                      : Colors.white.withValues(alpha: .68),
            ),
          ),
          child: _artwork(active),
        ),
        const SizedBox(height: 4),
        Text(
          checkpoint.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF626B6D),
            fontSize: 7,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _artwork(bool active) {
    if (checkpoint.isCompleted) {
      return Icon(
        Icons.check_rounded,
        size: 21,
        color: active ? const Color(0xFF5B7675) : const Color(0xFF9BA4A4),
      );
    }
    return CatalogArtwork(
      assetPath: checkpoint.assetPath,
      width: 36,
      height: 36,
      semanticLabel: checkpoint.title,
      placeholder: Icon(
        Icons.landscape_outlined,
        size: 21,
        color: active ? const Color(0xFF5B7675) : const Color(0xFF9BA4A4),
      ),
    );
  }
}

class _SkyQuoteCard extends ConsumerWidget {
  const _SkyQuoteCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteState = ref.watch(dailyQuoteProvider);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.fromLTRB(30, 30, 26, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF4EEFE), MuseColors.cream],
        ),
        borderRadius: BorderRadius.circular(48),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: -10,
            top: -25,
            child: Text(
              '“',
              style: TextStyle(
                color: Color(0x336D6680),
                fontSize: 50,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: quoteState.when(
              data:
                  (quote) => Text(
                    '“${quote.content}”',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF5B5865),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
              loading:
                  () => const Center(
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              error:
                  (_, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Chưa thể tải lời nhắn hôm nay.',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(dailyQuoteProvider),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareMoments extends StatelessWidget {
  const _ShareMoments();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 18,
              color: Color(0xFF366672),
            ),
            SizedBox(width: 7),
            Text(
              'Chia sẻ khoảnh khắc',
              style: TextStyle(
                color: Color(0xFF4F666A),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 244,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _MomentCard(
                title: 'Tuần sống lành',
                subtitle: 'Template 7 ngày',
                preview: _MomentPreview.lines,
              ),
              _MomentCard(
                title: 'Tháng qua của bạn',
                subtitle: 'Tổng hợp 6 ảnh',
                preview: _MomentPreview.grid,
              ),
              _MomentCard(
                title: 'Một năm dịu dàng',
                subtitle: 'Những điều đáng nhớ',
                preview: _MomentPreview.sparkles,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({
    required this.title,
    required this.subtitle,
    required this.preview,
  });

  final String title;
  final String subtitle;
  final _MomentPreview preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 238,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .85)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MomentPreviewPane(type: preview),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF4D4D4A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF777773), fontSize: 10),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 34,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Mẫu chia sẻ “$title” sẽ được hoàn thiện ở vòng tiếp theo.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.share_outlined, size: 15),
              label: const Text('Chia sẻ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF366672),
                backgroundColor: const Color(0xFFF3F2ED),
                side: BorderSide.none,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _MomentPreview { lines, grid, sparkles }

class _MomentPreviewPane extends StatelessWidget {
  const _MomentPreviewPane({required this.type});

  final _MomentPreview type;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: 116,
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4EC),
          borderRadius: BorderRadius.circular(24),
        ),
        child: switch (type) {
          _MomentPreview.lines => const _MomentLinesPreview(),
          _MomentPreview.grid => const _MomentGridPreview(),
          _MomentPreview.sparkles => const Center(
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 42,
              color: Color(0xFFA9B9AC),
            ),
          ),
        },
      ),
    );
  }
}

class _MomentLinesPreview extends StatelessWidget {
  const _MomentLinesPreview();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PreviewLine(width: 134),
        SizedBox(height: 9),
        _PreviewLine(width: 82),
        SizedBox(height: 9),
        _PreviewLine(width: 148),
        SizedBox(height: 9),
        _PreviewLine(width: 112),
      ],
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFCED5C9),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _MomentGridPreview extends StatelessWidget {
  const _MomentGridPreview();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.55,
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      children: List.generate(
        6,
        (index) => DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFDCEBED),
            borderRadius: BorderRadius.circular(8),
          ),
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
