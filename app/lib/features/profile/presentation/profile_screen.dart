import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/notifications/application/notification_providers.dart';
import 'package:musemend/features/notifications/domain/inbox_notification.dart';
import 'package:musemend/features/profile/application/profile_providers.dart';
import 'package:musemend/features/profile/domain/account_overview.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _settingsExpanded = false;
  bool _privacyExpanded = false;
  bool _termsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final session = ref.watch(authSessionProvider).asData?.value;
    final operation = ref.watch(authControllerProvider);
    final overview = ref.watch(accountOverviewProvider);
    final notifications = ref.watch(notificationInboxProvider);
    return MusePageBackground(
      accent: MuseColors.mint,
      child: SafeArea(
        child: MuseResponsiveList(
          top: 20,
          children: [
            MuseTopBar(trailing: MusePageBadge(label: strings.navProfile)),
            const SizedBox(height: 4),
            MusePageTagline(strings.profileTagline),
            const SizedBox(height: 28),
            overview.when(
              loading:
                  () => const MuseGlassCard(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              error:
                  (_, _) => MuseGlassCard(
                    child: ListTile(
                      leading: const Icon(Icons.cloud_off_rounded),
                      title: Text(strings.profileLoadFailed),
                      trailing: IconButton(
                        onPressed:
                            () => ref.invalidate(accountOverviewProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ),
                  ),
              data: (data) {
                return MuseGlassCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_rounded),
                        ),
                        title: Text(
                          data.profile.displayName ?? strings.profileMuseFriend,
                        ),
                        subtitle: Text(
                          session?.email ?? strings.profileProtectedEmail,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.cloud_rounded),
                        title: Text(strings.profileCloudNameTitle),
                        trailing: Text(
                          data.settings.cloudName.trim().isEmpty
                              ? strings.defaultCloudName
                              : data.settings.cloudName,
                        ),
                      ),
                      SwitchListTile(
                        value: data.settings.notificationEnabled,
                        onChanged: null,
                        secondary: const Icon(Icons.notifications_outlined),
                        title: Text(strings.notifications),
                        subtitle: Text(strings.profileFutureLetterReminder),
                      ),
                      ListTile(
                        leading: const Icon(Icons.tune_rounded),
                        title: Text(strings.profileEditSettings),
                        trailing: AnimatedRotation(
                          turns: _settingsExpanded ? .5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(Icons.expand_more_rounded),
                        ),
                        onTap:
                            () => setState(() {
                              _settingsExpanded = !_settingsExpanded;
                            }),
                      ),
                      if (_settingsExpanded) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          child: _InlineSettingsForm(
                            key: ValueKey(
                              '${data.profile.displayName}|'
                              '${data.settings.cloudName}|'
                              '${data.settings.themeMode}|'
                              '${data.settings.soundEnabled}|'
                              '${data.settings.notificationEnabled}|'
                              '${data.settings.languageCode}',
                            ),
                            overview: data,
                            onSave: (draft) => _saveSettings(context, draft),
                            onCancel:
                                () => setState(() => _settingsExpanded = false),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              strings.profileInboxTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            notifications.when(
              loading:
                  () => const MuseGlassCard(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              error:
                  (_, _) => MuseGlassCard(
                    child: ListTile(
                      leading: const Icon(Icons.cloud_off_rounded),
                      title: Text(strings.profileInboxLoadFailed),
                      trailing: IconButton(
                        onPressed:
                            () => ref.invalidate(notificationInboxProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ),
                  ),
              data:
                  (items) =>
                      items.isEmpty
                          ? MuseGlassCard(
                            child: ListTile(
                              leading: Icon(Icons.notifications_none_rounded),
                              title: Text(strings.profileInboxEmpty),
                              subtitle: Text(
                                strings.profileInboxEmptyDescription,
                              ),
                            ),
                          )
                          : MuseGlassCard(
                            child: Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < items.length;
                                  index++
                                )
                                  _NotificationTile(
                                    notification: items[index],
                                    showDivider: index < items.length - 1,
                                    onTap: () async {
                                      final opened = await ref
                                          .read(
                                            notificationInboxProvider.notifier,
                                          )
                                          .open(items[index]);
                                      if (opened && context.mounted) {
                                        context.go(
                                          Uri(
                                            path: '/journal',
                                            queryParameters: {
                                              'open': items[index].journalId,
                                            },
                                          ).toString(),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ),
            ),
            const SizedBox(height: 16),
            MuseGlassCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(strings.profilePrivacyTitle),
                    trailing: AnimatedRotation(
                      turns: _privacyExpanded ? .5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(Icons.expand_more_rounded),
                    ),
                    onTap:
                        () => setState(
                          () => _privacyExpanded = !_privacyExpanded,
                        ),
                  ),
                  if (_privacyExpanded)
                    _InlineInformationBody(body: strings.profilePrivacyBody),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(strings.profileTermsTitle),
                    trailing: AnimatedRotation(
                      turns: _termsExpanded ? .5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(Icons.expand_more_rounded),
                    ),
                    onTap:
                        () => setState(() => _termsExpanded = !_termsExpanded),
                  ),
                  if (_termsExpanded)
                    _InlineInformationBody(body: strings.profileTermsBody),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed:
                  operation.isLoading
                      ? null
                      : () =>
                          ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: Text(strings.profileSignOut),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed:
                  operation.isLoading
                      ? null
                      : () => _requestDeletion(context, ref),
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(strings.profileRequestDeletion),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings(BuildContext context, _SettingsDraft draft) async {
    final saved = await ref
        .read(accountOverviewProvider.notifier)
        .save(
          displayName: draft.displayName,
          cloudName: draft.cloudName,
          themeMode: draft.themeMode,
          soundEnabled: draft.soundEnabled,
          notificationEnabled: draft.notificationEnabled,
          languageCode: draft.languageCode,
        );
    if (saved && !draft.notificationEnabled) {
      try {
        await ref.read(notificationServiceProvider).cancelAll();
      } catch (_) {
        // Server settings remain authoritative if local cancellation fails.
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? AppLocalizations.of(context).settingsUpdated
              : AppLocalizations.of(context).settingsUpdateFailed,
        ),
      ),
    );
  }

  Future<void> _requestDeletion(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed != true) return;
    final requested =
        await ref.read(accountOverviewProvider.notifier).requestDeletion();
    if (!requested) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).profileDeletionRequestFailed,
          ),
        ),
      );
      return;
    }
    try {
      await ref.read(notificationServiceProvider).cancelAll();
    } catch (_) {
      // Account deletion is server-side and must not depend on local state.
    }
    await ref.read(authControllerProvider.notifier).signOut();
  }
}

class _InlineInformationBody extends StatelessWidget {
  const _InlineInformationBody({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(56, 0, 20, 18),
      child: Text(
        body,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55),
      ),
    );
  }
}

class _SettingsFieldLabel extends StatelessWidget {
  const _SettingsFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: MuseColors.teal,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _MuseSelectOption {
  const _MuseSelectOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _MusePopupField extends StatelessWidget {
  const _MusePopupField({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onSelected,
    this.helperText,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<_MuseSelectOption> options;
  final ValueChanged<String> onSelected;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = options.firstWhere((option) => option.value == value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsFieldLabel(label),
        const SizedBox(height: 6),
        PopupMenuButton<String>(
          initialValue: value,
          tooltip: label,
          position: PopupMenuPosition.under,
          offset: const Offset(0, 6),
          color: theme.colorScheme.surface.withValues(alpha: .98),
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          constraints: const BoxConstraints(
            minWidth: 220,
            maxWidth: 320,
            maxHeight: 360,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withValues(alpha: .8)),
          ),
          onSelected: onSelected,
          itemBuilder:
              (context) => [
                for (final option in options)
                  PopupMenuItem<String>(
                    value: option.value,
                    height: 42,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child:
                              option.value == value
                                  ? const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: MuseColors.teal,
                                  )
                                  : null,
                        ),
                        Expanded(
                          child: Text(
                            option.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: .78,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: MuseColors.teal.withValues(alpha: .16)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: MuseColors.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selected.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more_rounded, color: MuseColors.teal),
              ],
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(helperText!, style: theme.textTheme.bodySmall),
          ),
        ],
      ],
    );
  }
}

class _InlineSettingsForm extends StatefulWidget {
  const _InlineSettingsForm({
    required this.overview,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  final AccountOverview overview;
  final Future<void> Function(_SettingsDraft draft) onSave;
  final VoidCallback onCancel;

  @override
  State<_InlineSettingsForm> createState() => _InlineSettingsFormState();
}

class _InlineSettingsFormState extends State<_InlineSettingsForm> {
  late final _displayName = TextEditingController(
    text: widget.overview.profile.displayName ?? '',
  );
  late final _cloudName = TextEditingController(
    text: widget.overview.settings.cloudName,
  );
  late String _themeMode = widget.overview.settings.themeMode;
  late bool _soundEnabled = widget.overview.settings.soundEnabled;
  late bool _notificationEnabled = widget.overview.settings.notificationEnabled;
  late String _languageCode = widget.overview.settings.languageCode ?? 'system';

  @override
  void dispose() {
    _displayName.dispose();
    _cloudName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsFieldLabel(strings.displayName),
        const SizedBox(height: 6),
        TextField(
          controller: _displayName,
          maxLength: 80,
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 8),
        _SettingsFieldLabel(strings.cloudName),
        const SizedBox(height: 6),
        TextField(
          controller: _cloudName,
          maxLength: 40,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 8),
        _MusePopupField(
          label: strings.language,
          icon: Icons.language_rounded,
          value: _languageCode,
          helperText: strings.languageAutomaticDescription,
          options: [
            _MuseSelectOption(
              value: 'system',
              label: strings.languageAutomatic,
            ),
            const _MuseSelectOption(value: 'en', label: 'English'),
            const _MuseSelectOption(value: 'vi', label: 'Tiếng Việt'),
            const _MuseSelectOption(value: 'ja', label: '日本語'),
            const _MuseSelectOption(value: 'fr', label: 'Français'),
            const _MuseSelectOption(value: 'es', label: 'Español'),
            const _MuseSelectOption(value: 'it', label: 'Italiano'),
            const _MuseSelectOption(value: 'de', label: 'Deutsch'),
            const _MuseSelectOption(value: 'ko', label: '한국어'),
            const _MuseSelectOption(value: 'pt', label: 'Português'),
            const _MuseSelectOption(value: 'ms', label: 'Bahasa Melayu'),
            const _MuseSelectOption(value: 'id', label: 'Bahasa Indonesia'),
            const _MuseSelectOption(value: 'th', label: 'ไทย'),
          ],
          onSelected: (value) => setState(() => _languageCode = value),
        ),
        const SizedBox(height: 14),
        _MusePopupField(
          label: strings.appearance,
          icon: Icons.palette_outlined,
          value: _themeMode,
          options: [
            _MuseSelectOption(value: 'system', label: strings.themeSystem),
            _MuseSelectOption(value: 'light', label: strings.themeLight),
            _MuseSelectOption(value: 'dark', label: strings.themeDark),
          ],
          onSelected: (value) => setState(() => _themeMode = value),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _soundEnabled,
          onChanged: (value) => setState(() => _soundEnabled = value),
          title: Text(strings.sound),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _notificationEnabled,
          onChanged: (value) => setState(() => _notificationEnabled = value),
          title: Text(strings.notifications),
          subtitle: Text(strings.profileFutureLetterReminder),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: Text(strings.cancel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed:
                    _cloudName.text.trim().isEmpty
                        ? null
                        : () => widget.onSave(
                          _SettingsDraft(
                            displayName: _nullable(_displayName.text),
                            cloudName: _cloudName.text.trim(),
                            themeMode: _themeMode,
                            soundEnabled: _soundEnabled,
                            notificationEnabled: _notificationEnabled,
                            languageCode:
                                _languageCode == 'system'
                                    ? null
                                    : _languageCode,
                          ),
                        ),
                child: Text(strings.save),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _SettingsDraft {
  const _SettingsDraft({
    required this.displayName,
    required this.cloudName,
    required this.themeMode,
    required this.soundEnabled,
    required this.notificationEnabled,
    required this.languageCode,
  });

  final String? displayName;
  final String cloudName;
  final String themeMode;
  final bool soundEnabled;
  final bool notificationEnabled;
  final String? languageCode;
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(strings.profileDeleteTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.profileDeleteBody),
          const SizedBox(height: 16),
          Text(
            strings.profileDeleteConfirmationPrompt(
              strings.profileDeleteConfirmationKeyword,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmation,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: strings.profileDeleteConfirmationKeyword,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed:
              _confirmation.text.trim() ==
                      strings.profileDeleteConfirmationKeyword
                  ? () => Navigator.pop(context, true)
                  : null,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(strings.profileDeleteAccount),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.showDivider,
    required this.onTap,
  });

  final InboxNotification notification;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final local = notification.scheduledFor.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(
            notification.isUnread
                ? Icons.mark_email_unread_rounded
                : Icons.drafts_rounded,
          ),
          title: Text(strings.profileFutureLetterDue),
          subtitle: Text(strings.profileFutureLetterScheduled(date)),
          trailing:
              notification.isUnread
                  ? const Icon(Icons.circle, size: 10)
                  : const Icon(Icons.chevron_right_rounded),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
