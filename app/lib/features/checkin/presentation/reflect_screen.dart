import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/features/checkin/application/reflect_providers.dart';
import 'package:musemend/features/checkin/application/reflect_state.dart';
import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/checkin/presentation/mood_visuals.dart';
import 'package:musemend/features/checkin/presentation/sky_scene.dart';
import 'package:musemend/features/journey/application/journey_providers.dart';
import 'package:musemend/features/journey/domain/journey_checkpoint.dart';
import 'package:musemend/features/journey/domain/journey_dashboard.dart';
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

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE0F2F7), Color(0xFFFBF9F5), Color(0xFFFBF9F5)],
          stops: [0, .56, 1],
        ),
      ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MissionsSection(
                  skyStyle: true,
                  skyEnergyEarned: checkpoint?.earnedEnergy,
                  skyEnergyRequired: checkpoint?.requiredEnergy,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
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
    for (final checkpoint in journey?.province?.checkpoints ?? const []) {
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
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 560,
          child: SkyScene(height: 560),
        ),
        const Positioned(
          top: 294,
          left: 0,
          right: 0,
          height: 337,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00E0F2F7), Color(0xFFE0F2F7)],
                ),
              ),
            ),
          ),
        ),
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: _SkyHeader(streak: streak, energy: energy),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _JourneyOverview(journey: journey),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ],
    );
  }
}

class _SkyHeader extends StatelessWidget {
  const _SkyHeader({required this.streak, this.energy});

  final int streak;
  final int? energy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Mở menu',
              onPressed: () {},
              icon: const Icon(Icons.menu_rounded, size: 20),
            ),
            Text(
              'MuseMend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF6C9B7A),
                fontWeight: FontWeight.w600,
                letterSpacing: .1,
              ),
            ),
            const Spacer(),
            Semantics(
              label: '${energy ?? 0} năng lượng, streak $streak ngày',
              child: SizedBox.square(
                dimension: 44,
                child: IconButton(
                  tooltip: 'Bộ sưu tập và năng lượng',
                  onPressed: () {},
                  icon: const Icon(
                    Icons.card_giftcard_rounded,
                    color: Color(0xFFF4C84A),
                    size: 20,
                  ),
                ),
              ),
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
                  _MoodActionButton(
                    width: 91,
                    label: 'LƯU NHANH',
                    semanticLabel:
                        hasExistingCheckin
                            ? 'Cập nhật check-in hôm nay'
                            : 'Lưu nhanh check-in hôm nay',
                    onPressed: onSave,
                  ),
                  const SizedBox(width: 7),
                  _MoodActionButton(
                    width: 137,
                    label: 'LƯU VÀ VIẾT TÂM TƯ',
                    onPressed: onSaveAndWrite,
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
    required this.width,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final double width;
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
          width: width,
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
    final province = journey?.province;
    final checkpoints = province?.checkpoints ?? const [];
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
          'Hành trình Việt Nam, trạm $currentNumber trên ${checkpoints.length}',
      child: SizedBox(
        height: 142,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'VIỆT NAM',
                  style: TextStyle(
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
          child: Icon(
            checkpoint.isCompleted
                ? Icons.check_rounded
                : Icons.landscape_outlined,
            size: 21,
            color: active ? const Color(0xFF5B7675) : const Color(0xFF9BA4A4),
          ),
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
}

class _SkyQuoteCard extends StatelessWidget {
  const _SkyQuoteCard();

  static const quote =
      '“Chỉ cần bạn không dừng lại thì việc bạn tiến chậm cũng không là vấn đề.”';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 27, 25, 23),
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
      child: Text(
        quote,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF5B5865),
          fontSize: 16,
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
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
        Text(
          'Chia sẻ khoảnh khắc',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _MomentCard(
                icon: Icons.wb_sunny_outlined,
                label: 'Một điều nhỏ\nkhiến cậu mỉm cười',
                color: Color(0xFFFFE8B6),
              ),
              _MomentCard(
                icon: Icons.water_drop_outlined,
                label: 'Cho mình một\nhơi thở thật sâu',
                color: Color(0xFFDDF2F5),
              ),
              _MomentCard(
                icon: Icons.local_florist_outlined,
                label: 'Gửi lời dịu dàng\ncho ngày mai',
                color: Color(0xFFE9E1FA),
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
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: MuseColors.ink),
          const Spacer(),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
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
