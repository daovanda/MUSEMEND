import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/features/journey/application/journey_providers.dart';
import 'package:musemend/features/journey/domain/journey_checkpoint.dart';
import 'package:musemend/features/journey/domain/journey_dashboard.dart';
import 'package:musemend/features/journey/domain/journey_status.dart';
import 'package:musemend/features/journey/domain/library_collectible.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(journeyControllerProvider);
    return ColoredBox(
      color: MuseColors.lavender,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: ref.read(journeyControllerProvider.notifier).reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            children: [
              Text(
                'Hành trình',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Biến những điều nhỏ bạn hoàn thành thành một chuyến đi qua Việt Nam.',
              ),
              const SizedBox(height: 20),
              dashboard.when(
                loading: () => const _LoadingCard(),
                error:
                    (_, _) => _ErrorCard(
                      onRetry:
                          ref.read(journeyControllerProvider.notifier).reload,
                    ),
                data: (value) => _DashboardContent(dashboard: value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.dashboard});

  final JourneyDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _JourneyCard(dashboard: dashboard),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Bộ sưu tập',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Text('${dashboard.collectibles.length} đã mở'),
          ],
        ),
        const SizedBox(height: 12),
        _CollectionSummary(items: dashboard.collectibles),
        const SizedBox(height: 12),
        if (dashboard.collectibles.isEmpty)
          const _EmptyCollection()
        else
          ...dashboard.collectibles.map(_CollectibleCard.new),
      ],
    );
  }
}

class _JourneyCard extends ConsumerWidget {
  const _JourneyCard({required this.dashboard});

  final JourneyDashboard dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final province = dashboard.province;
    return Card(
      color: Colors.white.withValues(alpha: 0.82),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: MuseColors.cream,
                  child: Icon(Icons.explore_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        province?.name ?? _journeyTitle(dashboard.status),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${dashboard.availableEnergy} năng lượng sẵn sàng',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Đồng bộ tiến độ',
                  onPressed:
                      dashboard.status == JourneyStatus.inProgress
                          ? () => _advance(context, ref)
                          : null,
                  icon: const Icon(Icons.sync_rounded),
                ),
              ],
            ),
            if (province == null) ...[
              const SizedBox(height: 18),
              const Text(
                'Khởi hành để mở tỉnh đầu tiên. Mỗi trạm dùng năng lượng tích lũy và phần thưởng do máy chủ xác định.',
              ),
            ] else ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: province.completionPercent / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 6),
              Text('${province.completionPercent}% tỉnh đã khám phá'),
              const SizedBox(height: 16),
              ...province.checkpoints.map(
                (checkpoint) => _CheckpointRow(
                  checkpoint: checkpoint,
                  isPointer: checkpoint.id == dashboard.currentCheckpointId,
                ),
              ),
            ],
            if (dashboard.canStart &&
                dashboard.status != JourneyStatus.completed) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _start(context, ref),
                icon: const Icon(Icons.directions_walk_rounded),
                label: Text(
                  dashboard.status == JourneyStatus.paused
                      ? 'Đến tỉnh tiếp theo'
                      : 'Bắt đầu hành trình',
                ),
              ),
            ],
            if (dashboard.status == JourneyStatus.completed) ...[
              const SizedBox(height: 18),
              const Text(
                'Bạn đã hoàn thành toàn bộ hành trình hiện có. Những tỉnh mới sẽ được bổ sung sau.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(journeyControllerProvider.notifier).start();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Hành trình đã sẵn sàng.'
              : 'Chưa thể bắt đầu hành trình. Hãy thử lại.',
        ),
      ),
    );
  }

  Future<void> _advance(BuildContext context, WidgetRef ref) async {
    final success =
        await ref.read(journeyControllerProvider.notifier).refreshProgress();
    if (!context.mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chưa thể đồng bộ tiến độ. Hãy thử lại.')),
    );
  }

  String _journeyTitle(JourneyStatus status) {
    return switch (status) {
      JourneyStatus.notStarted => 'Chuyến đi đang chờ bạn',
      JourneyStatus.inProgress => 'Đang khám phá',
      JourneyStatus.paused => 'Sẵn sàng đi tiếp',
      JourneyStatus.completed => 'Đã hoàn thành hành trình',
    };
  }
}

class _CheckpointRow extends StatelessWidget {
  const _CheckpointRow({required this.checkpoint, required this.isPointer});

  final JourneyCheckpoint checkpoint;
  final bool isPointer;

  @override
  Widget build(BuildContext context) {
    final color =
        checkpoint.isCompleted
            ? Colors.green.shade700
            : isPointer
            ? MuseColors.ink
            : MuseColors.mutedInk;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            checkpoint.isCompleted
                ? Icons.check_circle
                : isPointer
                ? Icons.radio_button_checked
                : Icons.lock_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trạm ${checkpoint.number}: ${checkpoint.title}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: checkpoint.progress,
                  minHeight: 5,
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                ),
                const SizedBox(height: 3),
                Text(
                  '${checkpoint.earnedEnergy}/${checkpoint.requiredEnergy} năng lượng',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionSummary extends StatelessWidget {
  const _CollectionSummary({required this.items});

  final List<LibraryCollectible> items;

  @override
  Widget build(BuildContext context) {
    int count(CollectibleKind kind) =>
        items.where((item) => item.kind == kind).length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(label: Text('${count(CollectibleKind.landmark)} địa danh')),
        Chip(label: Text('${count(CollectibleKind.food)} món ăn')),
        Chip(label: Text('${count(CollectibleKind.item)} vật phẩm')),
      ],
    );
  }
}

class _CollectibleCard extends StatelessWidget {
  const _CollectibleCard(this.item);

  final LibraryCollectible item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(_icon(item.kind))),
        title: Text(item.name),
        subtitle: Text(_kindLabel(item.kind)),
        trailing:
            item.isEquipped
                ? const Icon(Icons.checkroom_rounded)
                : item.isViewed
                ? null
                : const Badge(label: Text('Mới')),
      ),
    );
  }

  IconData _icon(CollectibleKind kind) => switch (kind) {
    CollectibleKind.landmark => Icons.account_balance_outlined,
    CollectibleKind.food => Icons.restaurant_outlined,
    CollectibleKind.item => Icons.backpack_outlined,
  };

  String _kindLabel(CollectibleKind kind) => switch (kind) {
    CollectibleKind.landmark => 'Địa danh',
    CollectibleKind.food => 'Món ăn',
    CollectibleKind.item => 'Vật phẩm',
  };
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Hoàn thành một trạm để mở khóa địa danh và món ăn đầu tiên.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Chưa thể tải hành trình lúc này.'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
