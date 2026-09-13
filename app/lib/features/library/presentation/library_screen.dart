import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/core/presentation/catalog_artwork.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/features/journey/application/journey_providers.dart';
import 'package:musemend/features/journey/domain/journey_checkpoint.dart';
import 'package:musemend/features/journey/domain/journey_dashboard.dart';
import 'package:musemend/features/journey/domain/journey_destination.dart';
import 'package:musemend/features/journey/domain/journey_status.dart';
import 'package:musemend/features/journey/domain/library_collectible.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final dashboard = ref.watch(journeyControllerProvider);
    return MusePageBackground(
      accent: MuseColors.lavender,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: ref.read(journeyControllerProvider.notifier).reload,
          child: MuseResponsiveList(
            top: 20,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              MuseTopBar(trailing: MusePageBadge(label: strings.navExplore)),
              const SizedBox(height: 4),
              MusePageTagline(strings.exploreTagline),
              const SizedBox(height: 24),
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

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({required this.dashboard});

  final JourneyDashboard dashboard;

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  CollectibleKind? _filter;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final items =
        _filter == null
            ? widget.dashboard.collectibles
            : widget.dashboard.collectibles
                .where((item) => item.kind == _filter)
                .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _JourneyCard(dashboard: widget.dashboard),
        const SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.journeyCollection,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    strings.journeyUnlockedCount(
                      widget.dashboard.collectibles.length,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF81759A)),
          ],
        ),
        const SizedBox(height: 14),
        _CollectionFilters(
          items: widget.dashboard.collectibles,
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 16),
        if (widget.dashboard.collectibles.isEmpty)
          const _EmptyCollection()
        else if (items.isEmpty)
          _EmptyFilteredCollection(filter: _filter!)
        else
          ...items.map(_CollectibleCard.new),
      ],
    );
  }
}

class _JourneyCard extends ConsumerWidget {
  const _JourneyCard({required this.dashboard});

  final JourneyDashboard dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final destination = dashboard.destination;
    if (destination == null) {
      return _EmptyJourneyCard(
        dashboard: dashboard,
        onStart: () => _start(context, ref),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DestinationHero(destination: destination),
        const SizedBox(height: 14),
        MuseGlassCard(
          tint: MuseColors.sky,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ProgressMetric(
                      icon: Icons.route_rounded,
                      value: '${destination.completionPercent}%',
                      label: strings.journeyCompletedMetric,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProgressMetric(
                      icon: Icons.bolt_rounded,
                      value: '${dashboard.availableEnergy}',
                      label: strings.journeyEnergyReady,
                    ),
                  ),
                  IconButton(
                    tooltip: strings.journeySync,
                    onPressed:
                        dashboard.status == JourneyStatus.inProgress
                            ? () => _advance(context, ref)
                            : null,
                    icon: const Icon(Icons.sync_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: destination.completionPercent / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: Colors.white.withValues(alpha: .68),
              ),
              const SizedBox(height: 22),
              Text(
                strings.journeyWaitingStops,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...destination.checkpoints.map(
                (checkpoint) => _CheckpointCard(
                  checkpoint: checkpoint,
                  isPointer: checkpoint.id == dashboard.currentCheckpointId,
                ),
              ),
              if (dashboard.canStart &&
                  dashboard.status != JourneyStatus.completed) ...[
                const SizedBox(height: 6),
                FilledButton.icon(
                  onPressed: () => _start(context, ref),
                  icon: const Icon(Icons.directions_walk_rounded),
                  label: Text(
                    dashboard.status == JourneyStatus.paused
                        ? strings.journeyNextDestination
                        : strings.journeyStart,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (dashboard.status == JourneyStatus.completed)
                Padding(
                  padding: EdgeInsets.fromLTRB(4, 8, 4, 14),
                  child: Text(
                    strings.journeyAllCompleted,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final strings = AppLocalizations.of(context);
    final success = await ref.read(journeyControllerProvider.notifier).start();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? strings.journeyReady : strings.journeyStartFailed,
        ),
      ),
    );
  }

  Future<void> _advance(BuildContext context, WidgetRef ref) async {
    final success =
        await ref.read(journeyControllerProvider.notifier).refreshProgress();
    if (!context.mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).journeySyncFailed)),
    );
  }
}

class _DestinationHero extends StatelessWidget {
  const _DestinationHero({required this.destination});

  final JourneyDestination destination;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Semantics(
      label: strings.destinationSemantics(
        destination.name,
        destination.description ?? '',
      ),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F44536A),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFDDEEF3), Color(0xFFE8E0F4)],
                  ),
                ),
                child: CatalogArtwork(
                  assetPath: destination.heroAssetPath,
                  fit: BoxFit.cover,
                  semanticLabel: strings.destinationImageSemantics(
                    destination.name,
                  ),
                  placeholder: const Icon(
                    Icons.landscape_rounded,
                    size: 72,
                    color: Color(0x66718087),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x08000000), Color(0xC7444A50)],
                    stops: [0.35, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (destination.countryCode != null)
                          _HeroPill(label: destination.countryCode!),
                        _HeroPill(
                          label: _destinationTypeLabel(
                            strings,
                            destination.destinationType,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      destination.name,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (destination.description case final description?) ...[
                      const SizedBox(height: 7),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: .94),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _destinationTypeLabel(AppLocalizations strings, String value) =>
      switch (value) {
        'province' => strings.destinationProvince,
        'city' => strings.destinationCity,
        'island' => strings.destinationIsland,
        'heritage' => strings.destinationHeritage,
        'region' => strings.destinationRegion,
        _ => strings.destinationDefault,
      };
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4D5960),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF668284), size: 22),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckpointCard extends StatelessWidget {
  const _CheckpointCard({required this.checkpoint, required this.isPointer});

  final JourneyCheckpoint checkpoint;
  final bool isPointer;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final color =
        checkpoint.isCompleted
            ? const Color(0xFF6E987F)
            : isPointer
            ? const Color(0xFF617F83)
            : MuseColors.mutedInk;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isPointer
                  ? const Color(0x666D9195)
                  : Colors.white.withValues(alpha: .72),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColoredBox(
              color: const Color(0xFFE8F0EF),
              child: CatalogArtwork(
                assetPath: checkpoint.assetPath,
                width: 92,
                height: 92,
                fit: BoxFit.cover,
                semanticLabel: checkpoint.title,
                placeholder: Icon(
                  checkpoint.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.landscape_outlined,
                  color: color,
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.checkpointTitle(
                            checkpoint.number,
                            checkpoint.title,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        checkpoint.isCompleted
                            ? Icons.check_circle_rounded
                            : isPointer
                            ? Icons.near_me_rounded
                            : Icons.lock_outline_rounded,
                        color: color,
                        size: 20,
                      ),
                    ],
                  ),
                  if (checkpoint.description case final description?) ...[
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 9),
                  LinearProgressIndicator(
                    value: checkpoint.progress,
                    minHeight: 5,
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.checkpointEnergy(
                      checkpoint.earnedEnergy,
                      checkpoint.requiredEnergy,
                    ),
                    style: Theme.of(context).textTheme.labelSmall,
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

class _EmptyJourneyCard extends StatelessWidget {
  const _EmptyJourneyCard({required this.dashboard, required this.onStart});

  final JourneyDashboard dashboard;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return MuseGlassCard(
      tint: MuseColors.sky,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: MuseColors.cream,
            child: Icon(Icons.public_rounded, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            _journeyTitle(strings, dashboard.status),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(strings.journeyStartDescription, textAlign: TextAlign.center),
          if (dashboard.canStart &&
              dashboard.status != JourneyStatus.completed) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.directions_walk_rounded),
              label: Text(strings.journeyStart),
            ),
          ],
        ],
      ),
    );
  }

  String _journeyTitle(AppLocalizations strings, JourneyStatus status) =>
      switch (status) {
        JourneyStatus.notStarted => strings.journeyStatusNotStarted,
        JourneyStatus.inProgress => strings.journeyStatusInProgress,
        JourneyStatus.paused => strings.journeyStatusPaused,
        JourneyStatus.completed => strings.journeyStatusCompleted,
      };
}

class _CollectionFilters extends StatelessWidget {
  const _CollectionFilters({
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<LibraryCollectible> items;
  final CollectibleKind? selected;
  final ValueChanged<CollectibleKind?> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    int count(CollectibleKind kind) =>
        items.where((item) => item.kind == kind).length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterPill(
            label: strings.filterAll,
            count: items.length,
            icon: Icons.auto_awesome_mosaic_outlined,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          _FilterPill(
            label: strings.collectibleLandmark,
            count: count(CollectibleKind.landmark),
            icon: Icons.account_balance_outlined,
            selected: selected == CollectibleKind.landmark,
            onTap: () => onSelected(CollectibleKind.landmark),
          ),
          _FilterPill(
            label: strings.collectibleFood,
            count: count(CollectibleKind.food),
            icon: Icons.restaurant_outlined,
            selected: selected == CollectibleKind.food,
            onTap: () => onSelected(CollectibleKind.food),
          ),
          _FilterPill(
            label: strings.collectibleItem,
            count: count(CollectibleKind.item),
            icon: Icons.backpack_outlined,
            selected: selected == CollectibleKind.item,
            onTap: () => onSelected(CollectibleKind.item),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        avatar: Icon(icon, size: 17),
        label: Text('$label · $count'),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _CollectibleCard extends StatelessWidget {
  const _CollectibleCard(this.item);

  final LibraryCollectible item;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MuseGlassCard(
        padding: const EdgeInsets.all(10),
        tint: _tint(item.kind),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ColoredBox(
                color: Colors.white.withValues(alpha: .72),
                child: CatalogArtwork(
                  assetPath: item.assetPath,
                  width: 78,
                  height: 78,
                  fit: BoxFit.cover,
                  semanticLabel: item.name,
                  placeholder: Icon(
                    _icon(item.kind),
                    size: 30,
                    color: const Color(0xFF66787B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (!item.isViewed)
                        Badge(label: Text(strings.newLabel))
                      else if (item.isEquipped)
                        const Icon(Icons.checkroom_rounded, size: 20),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_kindLabel(strings, item.kind)} · ${_rarityLabel(strings, item.rarity)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF6E7181),
                    ),
                  ),
                  if (item.description case final description?) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _tint(CollectibleKind kind) => switch (kind) {
    CollectibleKind.landmark => MuseColors.sky,
    CollectibleKind.food => MuseColors.cream,
    CollectibleKind.item => MuseColors.lavender,
  };

  IconData _icon(CollectibleKind kind) => switch (kind) {
    CollectibleKind.landmark => Icons.account_balance_outlined,
    CollectibleKind.food => Icons.restaurant_outlined,
    CollectibleKind.item => Icons.backpack_outlined,
  };

  String _kindLabel(AppLocalizations strings, CollectibleKind kind) =>
      switch (kind) {
        CollectibleKind.landmark => strings.collectibleLandmark,
        CollectibleKind.food => strings.collectibleFood,
        CollectibleKind.item => strings.collectibleItem,
      };

  String _rarityLabel(AppLocalizations strings, String rarity) =>
      switch (rarity) {
        'common' => strings.rarityCommon,
        'uncommon' => strings.rarityUncommon,
        'rare' => strings.rarityRare,
        'epic' => strings.rarityEpic,
        'legendary' => strings.rarityLegendary,
        _ => rarity,
      };
}

class _EmptyFilteredCollection extends StatelessWidget {
  const _EmptyFilteredCollection({required this.filter});

  final CollectibleKind filter;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final label = switch (filter) {
      CollectibleKind.landmark => strings.collectibleLandmark.toLowerCase(),
      CollectibleKind.food => strings.collectibleFood.toLowerCase(),
      CollectibleKind.item => strings.collectibleItem.toLowerCase(),
    };
    return MuseGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          strings.collectionFilteredEmpty(label),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection();

  @override
  Widget build(BuildContext context) {
    return MuseGlassCard(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          AppLocalizations.of(context).collectionEmpty,
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
    return const MuseGlassCard(
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
    return MuseGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(AppLocalizations.of(context).journeyLoadFailed),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}
