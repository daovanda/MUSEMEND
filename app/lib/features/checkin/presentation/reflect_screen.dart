import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/features/checkin/application/reflect_providers.dart';
import 'package:musemend/features/checkin/application/reflect_state.dart';
import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/checkin/presentation/sky_scene.dart';
import 'package:musemend/features/journey/application/journey_providers.dart';
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              Theme.of(context).brightness == Brightness.dark
                  ? [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surfaceContainer,
                    Theme.of(context).colorScheme.surface,
                  ]
                  : [MuseColors.sky, MuseColors.cream, MuseColors.mint],
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
            final journey = journeyState?.asData?.value;
            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _SkyHeader(streak: data.streak, energy: journey?.currentEnergy),
                const SizedBox(
                  height: 244,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned.fill(child: SkyScene(height: 380)),
                      Positioned(top: 18, child: CloudMascot()),
                      Positioned(
                        top: 147,
                        child: _ChatBubble(text: 'Mây đang dịu dàng cùng cậu.'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _MoodCheckinCard(
                        selected: selected,
                        hasExistingCheckin: data.today != null,
                        onSelected:
                            (mood) => setState(() => _selectedMood = mood),
                        onSave: selected == null ? null : _save,
                        onSaveAndWrite: selected == null ? null : _saveAndWrite,
                        noteController: _noteController,
                        energyLevel: _energyLevel,
                        onEnergyChanged:
                            (value) => setState(() => _energyLevel = value),
                        onClearEnergy:
                            () => setState(() => _energyLevel = null),
                      ),
                      const SizedBox(height: 20),
                      _JourneyOverview(journey: journey),
                      const MissionsSection(skyStyle: true),
                      const SizedBox(height: 6),
                      const _SkyQuoteCard(),
                      const SizedBox(height: 24),
                      const _ShareMoments(),
                      const SizedBox(height: 16),
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.health_and_safety_outlined),
                          title: Text('Một khoảng dừng để tự lắng nghe'),
                          subtitle: Text(
                            'MuseMend hỗ trợ phản tư, không chẩn đoán và không '
                            'thay thế chuyên gia y tế hoặc sức khỏe tâm thần.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Mở menu',
              onPressed: () {},
              icon: const Icon(Icons.menu_rounded),
            ),
            const SizedBox(width: 4),
            Text(
              'MuseMend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: .2,
              ),
            ),
            const Spacer(),
            Semantics(
              label: '${energy ?? 0} năng lượng, streak $streak ngày',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 17)),
                    const SizedBox(width: 4),
                    Text('${energy ?? 0}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 185),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: Colors.white.withValues(alpha: .74)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
    required this.noteController,
    required this.energyLevel,
    required this.onEnergyChanged,
    required this.onClearEnergy,
  });

  final Mood? selected;
  final bool hasExistingCheckin;
  final ValueChanged<Mood> onSelected;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAndWrite;
  final TextEditingController noteController;
  final double? energyLevel;
  final ValueChanged<double> onEnergyChanged;
  final VoidCallback onClearEnergy;

  static const _displayLabels = {
    Mood.awful: 'QUẠO',
    Mood.sad: 'TRỐNG RỖNG',
    Mood.okay: 'ỔN ÁP',
    Mood.good: 'THƯ GIÃN',
    Mood.great: 'CHỮA LÀNH',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: .91),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          children: [
            Text(
              'Ngày hôm nay có dịu dàng với cậu không?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 3,
              runSpacing: 4,
              children: [
                for (final mood in Mood.values)
                  _MoodOption(
                    mood: mood,
                    label: _displayLabels[mood]!,
                    selected: mood == selected,
                    onTap: () => onSelected(mood),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text('Ghi lại thêm một chút (không bắt buộc)'),
              subtitle: Text(
                energyLevel == null
                    ? 'Năng lượng và ghi chú'
                    : 'Năng lượng ${energyLevel!.round()}/5',
              ),
              children: [
                TextField(
                  controller: noteController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Một dòng cho hôm nay',
                    alignLabelWithHint: true,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.battery_5_bar_rounded),
                    Expanded(
                      child: Slider(
                        value: energyLevel ?? 3,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: '${(energyLevel ?? 3).round()}/5',
                        onChanged: onEnergyChanged,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Bỏ chọn năng lượng',
                      onPressed: energyLevel == null ? null : onClearEnergy,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSave,
                    child: Text(hasExistingCheckin ? 'CẬP NHẬT' : 'LƯU NHANH'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onSaveAndWrite,
                    child: const Text('VIẾT TÂM TÌNH'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  const _MoodOption({
    required this.mood,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Mood mood;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, ${mood.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 58,
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
          decoration: BoxDecoration(
            color: selected ? MuseColors.lavender : const Color(0xFFF9F7F1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? MuseColors.coral : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(mood.symbol, style: const TextStyle(fontSize: 25)),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
    return Card(
      color: const Color(0xFFFFF4DC).withValues(alpha: .92),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'VIỆT NAM',
                  style: TextStyle(
                    letterSpacing: 1.3,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text('${province?.completionPercent ?? 0}%'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              province?.name ?? 'Hành trình của bạn',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              province?.description ??
                  'Mỗi bước nhỏ là một lần trở về với mình.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: (province?.completionPercent ?? 0) / 100,
                backgroundColor: Colors.white.withValues(alpha: .75),
                color: MuseColors.coral,
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                for (final checkpoint in checkpoints.take(5))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _CheckpointDot(
                        number: checkpoint.number,
                        completed: checkpoint.isCompleted,
                        current: checkpoint.isCurrent,
                      ),
                    ),
                  ),
              ],
            ),
            if (journey != null) ...[
              const SizedBox(height: 12),
              Text(
                '${journey!.availableEnergy} năng lượng sẵn sàng · ${journey!.journeyEnergyUsed} đã dùng cho hành trình',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CheckpointDot extends StatelessWidget {
  const _CheckpointDot({
    required this.number,
    required this.completed,
    required this.current,
  });

  final int number;
  final bool completed;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final color =
        completed
            ? MuseColors.coral
            : current
            ? MuseColors.lavender
            : Colors.white;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MuseColors.coral.withValues(alpha: .35)),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color:
              completed
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
        ),
      ),
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
