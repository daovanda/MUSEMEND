import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/onboarding/application/onboarding_providers.dart';
import 'package:musemend/features/onboarding/domain/onboarding_profile.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingProfileProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MusePageBackground(
        accent: MuseColors.mint,
        child: SafeArea(
          child: profile.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (_, _) => _OnboardingError(
                  onRetry: () => ref.invalidate(onboardingProfileProvider),
                ),
            data:
                (value) =>
                    value == null
                        ? const SizedBox.shrink()
                        : _OnboardingFlow(profile: value),
          ),
        ),
      ),
    );
  }
}

class _OnboardingFlow extends ConsumerStatefulWidget {
  const _OnboardingFlow({required this.profile});

  final OnboardingProfile profile;

  @override
  ConsumerState<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<_OnboardingFlow> {
  late final TextEditingController _nameController;
  var _step = 0;
  PreferredAddress? _preferredAddress;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _preferredAddress = widget.profile.preferredAddress;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool skip}) async {
    final strings = AppLocalizations.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    final name = _nameController.text.trim();
    if (!skip && name.isNotEmpty && (name.length < 2 || name.length > 80)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.onboardingNameLength)));
      return;
    }
    await ref
        .read(onboardingControllerProvider.notifier)
        .complete(
          displayName: skip || name.isEmpty ? null : name,
          preferredAddress: skip ? null : _preferredAddress,
        );
  }

  Future<void> _returnToSignIn() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final signedOut = await ref.read(authControllerProvider.notifier).signOut();
    if (!signedOut && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).authNetworkError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final operation = ref.watch(onboardingControllerProvider);
    final authOperation = ref.watch(authControllerProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
      child: MuseContentFrame(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip:
                      _step == 0
                          ? strings.onboardingBackToSignIn
                          : strings.back,
                  onPressed:
                      operation.isLoading || authOperation.isLoading
                          ? null
                          : _step == 0
                          ? _returnToSignIn
                          : () => setState(() => _step--),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Expanded(child: MuseTopBar()),
                TextButton(
                  onPressed:
                      operation.isLoading ? null : () => _finish(skip: true),
                  child: Text(strings.skip),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ProgressDots(step: _step),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(top: 8, bottom: 18),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: switch (_step) {
                    0 => const _WelcomeStep(key: ValueKey('welcome-step')),
                    1 => const _PrivacyStep(key: ValueKey('privacy-step')),
                    _ => _NameStep(
                      key: const ValueKey('name-step'),
                      controller: _nameController,
                      selected: _preferredAddress,
                      fallbackName:
                          widget.profile.displayName ??
                          strings.onboardingFallbackName,
                      onSelected:
                          (value) => setState(() => _preferredAddress = value),
                    ),
                  },
                ),
              ),
            ),
            if (operation.hasError) ...[
              const SizedBox(height: 8),
              Text(
                strings.onboardingSaveFailed,
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9A473D)),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: MuseColors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed:
                  operation.isLoading
                      ? null
                      : () {
                        if (_step < 2) {
                          setState(() => _step++);
                        } else {
                          _finish(skip: false);
                        }
                      },
              icon:
                  operation.isLoading
                      ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Icon(
                        _step == 2
                            ? Icons.cloud_done_outlined
                            : Icons.arrow_forward_rounded,
                      ),
              label: Text(
                _step == 2
                    ? strings.onboardingStartWithMuse
                    : strings.continueLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      children: [
        const _CloudEmblem(icon: Icons.waving_hand_rounded),
        const SizedBox(height: 24),
        Text(
          strings.onboardingWelcomeHeadline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: MuseColors.ink,
            fontWeight: FontWeight.w800,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 24),
        _OnboardingCard(
          icon: Icons.sentiment_satisfied_alt_rounded,
          tint: MuseColors.sky,
          title: strings.onboardingEmotionTitle,
          description: strings.onboardingEmotionDescription,
        ),
        const SizedBox(height: 12),
        _OnboardingCard(
          icon: Icons.lock_outline_rounded,
          tint: MuseColors.mint,
          title: strings.onboardingPrivateWritingTitle,
          description: strings.onboardingPrivateWritingDescription,
        ),
        const SizedBox(height: 12),
        _OnboardingCard(
          icon: Icons.spa_outlined,
          tint: Color(0xFFF8E6DC),
          title: strings.onboardingSmallStepsTitle,
          description: strings.onboardingSmallStepsDescription,
        ),
      ],
    );
  }
}

class _PrivacyStep extends StatelessWidget {
  const _PrivacyStep({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      children: [
        const _CloudEmblem(icon: Icons.shield_outlined),
        const SizedBox(height: 24),
        Text(
          strings.onboardingPrivacyHeadline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: MuseColors.ink,
            fontWeight: FontWeight.w800,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          strings.onboardingPrivacyBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: MuseColors.mutedInk,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        _OnboardingCard(
          icon: Icons.lock_rounded,
          tint: MuseColors.mint,
          title: strings.onboardingDeviceJournalTitle,
          description: strings.onboardingDeviceJournalDescription,
        ),
        const SizedBox(height: 12),
        _OnboardingCard(
          icon: Icons.wifi_off_rounded,
          tint: MuseColors.sky,
          title: strings.onboardingOfflineTitle,
          description: strings.onboardingOfflineDescription,
        ),
        const SizedBox(height: 12),
        _OnboardingCard(
          icon: Icons.cloud_sync_outlined,
          tint: MuseColors.lavender,
          title: strings.onboardingOptionalBackupTitle,
          description: strings.onboardingOptionalBackupDescription,
        ),
      ],
    );
  }
}

class _NameStep extends StatefulWidget {
  const _NameStep({
    required this.controller,
    required this.selected,
    required this.fallbackName,
    required this.onSelected,
    super.key,
  });

  final TextEditingController controller;
  final PreferredAddress? selected;
  final String fallbackName;
  final ValueChanged<PreferredAddress> onSelected;

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final typedName = widget.controller.text.trim();
    final previewName = typedName.isEmpty ? widget.fallbackName : typedName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CloudEmblem(icon: Icons.cloud_outlined),
        const SizedBox(height: 20),
        Text(
          strings.onboardingNamePrompt,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: MuseColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.onboardingNameCanChange,
          textAlign: TextAlign.center,
          style: TextStyle(color: MuseColors.mutedInk),
        ),
        const SizedBox(height: 22),
        MuseGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.onboardingDisplayNameLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: MuseColors.teal,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: widget.controller,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: strings.onboardingNameHint,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        MuseSectionLabel(strings.onboardingAddressLabel),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final address in PreferredAddress.values)
              MusePill(
                label: _preferredAddressLabel(strings, address),
                selected: widget.selected == address,
                onTap: () => widget.onSelected(address),
              ),
          ],
        ),
        const SizedBox(height: 24),
        MuseGlassCard(
          tint: MuseColors.cream,
          child: Column(
            children: [
              const Icon(Icons.waving_hand_outlined, color: MuseColors.teal),
              const SizedBox(height: 10),
              Text(
                strings.onboardingGreeting(previewName),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: MuseColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CloudEmblem extends StatelessWidget {
  const _CloudEmblem({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: .9),
              MuseColors.sky.withValues(alpha: .8),
              MuseColors.mint.withValues(alpha: .7),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .85)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon, size: 38, color: MuseColors.teal),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.icon,
    required this.tint,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return MuseGlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: tint,
            foregroundColor: MuseColors.teal,
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MuseColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MuseColors.mutedInk,
                    height: 1.42,
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

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < 3; index++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: index == step ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  index == step
                      ? MuseColors.teal
                      : Colors.white.withValues(alpha: .78),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          if (index < 2) const SizedBox(width: 7),
        ],
      ],
    );
  }
}

class _OnboardingError extends StatelessWidget {
  const _OnboardingError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: MuseContentFrame(
        child: MuseGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40),
              const SizedBox(height: 12),
              Text(strings.onboardingLoadFailed),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(strings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _preferredAddressLabel(
  AppLocalizations strings,
  PreferredAddress address,
) => switch (address) {
  PreferredAddress.cauMinh => strings.preferredAddressCauMinh,
  PreferredAddress.banMinh => strings.preferredAddressBanMinh,
  PreferredAddress.anhEm => strings.preferredAddressAnhEm,
  PreferredAddress.chiEm => strings.preferredAddressChiEm,
  PreferredAddress.tenRieng => strings.preferredAddressNameOnly,
};
